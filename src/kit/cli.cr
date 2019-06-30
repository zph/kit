module Kit
  class CLI
    def self.process_request(binaryname, config, done)
      platform = OS.platform
      bin = config["platform"][platform.to_name].as_h
      LOG.debug(bin)
      general = config["general"].as_h
      link, sha256, version = ["link", "sha256", "version"].map { |k| bin[k].to_s }
      output, version_cmd = ["output", "version_cmd"].map { |k| general[k].to_s }
      binaries = general["binaries"].as_a

      primary = [output, File.basename(binaries.first.to_s)].join("/")
      filename = link.split("/").last
      match = if File.exists?(primary) && File.executable?(primary)
                stdout, stderr, process = POpen.call(primary, [version_cmd].compact)
                version_string = [stdout.to_s, stderr.to_s].join(" ")
                LOG.debug(version_string)
                Regex.new(".*(#{version}).*").match(version_string)
              else
                Regex.new("x").match("y")
              end

      LOG.debug("match") { match }
      unless match && match.captures.size > 0
        response = Core.get(link)
        LOG.debug("response") { response }
        if response
          result = Core.write(response, sha256, filename, output, binaries)
          if general["post_install"]?
            post_install = general["post_install"].as_a
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

    def self.call(config)
      config = config["binaries"].as_h
      done = Channel(Int32).new
      config.each do |k, v|
        spawn do
          process_request(k, v, done)
        end
      end

      # Wait for threads to finish
      # TODO: handle orphaned threads if something fails
      config.keys.size.times do
        done.receive
      end
    end
  end
end
