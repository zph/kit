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

      output, version_cmd = general.output, general.version_cmd
      if !output
        raise("Missing output location")
      end

      binaries = general.binaries

      primary = [output, File.basename(binaries.first.to_s)].join("/")
      # Only valid for full http links with tar.gz, fails for shorthand tar.gz on Github
      match = case {primary, version_cmd}
              when {String, String}
                if File.exists?(primary) && File.executable?(primary)
                  stdout, stderr, process = POpen.call(primary, [version_cmd].compact)
                  version_string = [stdout.to_s, stderr.to_s].join(" ")
                  LOG.debug(version_string)
                  Regex.new(".*(#{version}).*").match(version_string)
                else
                  Regex.new("x").match("y")
                end
              end
      LOG.debug("match") { match }
      unless match && match.captures.size > 0
        link = Core.resolve_link(link, filter)
        response = Core.get(link)
        LOG.debug("response") { response }
        filename = link.split("/").last
        if response && filename
          result = Core.write(response, sha256, filename, output, binaries)
          if post_install = general.post_install
            LOG.info("post_install") { post_install }
            post_install.each do |hook|
              Process.run("bash", ["-c", hook.to_s], chdir: output)
            end
          end
          LOG.info("result") { result }
        end
      else
        LOG.info("Version is current") { [binaryname, match] }
      end
      done.send(1)
    end

    def self.call(config : Config::Core)
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
