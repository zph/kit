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

      output, version_cmd = general.output, general.version_cmd

      output_folder = File.expand_path(output.to_s)

      binaries = general.binaries

      LOG.debug("output_folder") { output_folder }
      primary = general.primary

      flags = ([version_cmd.to_s] + ["--version", "version", "-V", "-v", "-version"]).uniq

      unless Versioning.new(primary).match_any?(flags, version)
        link = Core.resolve_link(link, bin.filter)
        content = Core.get(link)
        filename = link.split("/").last
        if content && filename
          result = Core.write(content, sha256, filename, output_folder, binaries)
          if post_install = general.post_install
            post_install.each do |hook|
              LOG.info("post_install hook") { hook }
              POpen.call("bash", ["-c", hook.to_s], chdir: output_folder)
            end
          end
          LOG.info("result") { result }
        end
      else
        LOG.info("Version is current") { [binaryname, version] }
      end
      done.send(0)
    end

    def self.call(config : Config)
      # TODO: Use worker pool
      binaries = config.binaries
      done = Channel(Int32).new
      binaries.each do |k, v|
        spawn(name: k) do
          begin
            process_request(k, v, done)
          rescue e
            LOG.error("Fiber crashed: #{k}") { e }
            done.send(1)
          end
        end
      end

      exit_status = 0
      binaries.keys.size.times do
        exit_status += done.receive
      end

      exit(exit_status)
    end
  end
end
