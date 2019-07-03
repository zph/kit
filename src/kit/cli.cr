module Kit
  class CLI
    def self.reflect(v)
      String | Nil
      case i = v
      when .as_s? then i.to_s
      else
        nil
      end
    end

    def self.process_request(binaryname, config, done)
      platform = OS.platform
      bin = config.platform[platform.to_name]
      LOG.debug(bin)
      general = config.general
      link = bin.link
      # Allow for nil pattern matching on fn heads
      link, sha256, version = bin.link, bin.sha256, bin.version
      if !link
        raise("Missing link")
      end

      filter = if f = bin.filter
                 f
               else
                 ".*"
               end

      output, version_cmd = File.expand_path(general.output.to_s), general.version_cmd
      if output.empty?
        raise("Missing output location")
      end

      binaries = general.binaries

      LOG.debug("output") { output }
      primary = File.expand_path([output, File.basename(binaries.first.to_s)].join("/"))
      # Only valid for full http links with tar.gz, fails for shorthand tar.gz on Github
      match = case {primary, version_cmd}
              when {String, String}
                if File.exists?(primary) && File.executable?(primary)
                  LOG.debug("primary file location") { [primary, version_cmd].join(" ") }
                  Dir.cd(output) do
                    stdout, stderr, process = POpen.call(primary, [version_cmd].compact)
                    version_string = [stdout.to_s, stderr.to_s].join(" ")
                    LOG.debug(version_string)
                    Regex.new(".*(#{version}).*").match(version_string)
                  end
                else
                  Regex.new("x").match("y")
                end
              end
      LOG.debug("match") { match }
      unless (match && match.captures.size > 0)
        link = Core.resolve_link(link, filter)
        content = Core.get(link)
        filename = link.split("/").last
        if content && filename
          result = Core.write(content, sha256, filename, output, binaries)
          if post_install = general.post_install
            LOG.info("post_install") { post_install }
            post_install.each do |hook|
              Dir.cd(output) do
                POpen.call("bash", ["-c", hook.to_s])
              end
            end
          end
          LOG.info("result") { result }
        end
      else
        LOG.info("Version is current") { [binaryname, match] }
      end
      done.send(1)
    end

    def self.call(config : Config)
      binaries = config.binaries
      done = Channel(Int32).new
      binaries.each do |k, v|
        spawn do
          process_request(k, v, done)
        end
      end

      # Wait for threads to finish
      # TODO: handle orphaned threads if something fails
      binaries.keys.size.times do
        done.receive
      end
    end
  end
end
