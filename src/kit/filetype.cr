module Kit
  module Filetype
    def self.type?(filename)
      [Binary,
       Archive::Targz,
       Archive::Zip,
       Archive::Tarbz].find { |t| t.match?(filename) }
    end

    class Binary
      getter(binary : String) { @binaries.first }
      getter folder

      def initialize(@binaries : Array(String), @dir : String, @folder : String)
      end

      def self.match?(filename)
        !filename.includes?(".")
      end

      def process(src)
        output = [folder, binary].join("/")
        LOG.info("paths") { {src: src, output: output} }
        FileUtils.cp(src, File.expand_path(output))
        File.expand_path(output)
      end
    end

    module Archive
      abstract class Base
        abstract def extract(tmpfile : String, dir : String)

        def self.extensions : Array(String)
          raise "Must implement self.extensions in Subclass, ie [/zip$/]"
        end

        def self.match?(filename)
          extensions.find { |e| Regex.new("#{Regex.escape(e)}$", Regex::Options::IGNORE_CASE).match(filename) }
        end

        def initialize(@binaries : Array(String), @dir : String, @outputname : String)
        end

        def process_archive
          @binaries.to_a.map do |bin|
            match = Dir.glob("#{@dir}/{**/#{bin},#{bin}}").uniq
              .tap { |m| LOG.debug("glob_matches") { m } }
              .select do |m|
                # Pin exact file binary name match
                File.basename(m) == bin &&
                  File.file?(m)
              end
            LOG.debug("glob") { match }

            if match && match.size == 1
              Binary.new([bin], "", @outputname).process(match.first)
            else
              first_match = match.sort_by { |s| s.chars.count { |a| a } }
              LOG.error("Unable to find binary too many matching names #{match}")
              LOG.error("Using first match #{first_match}")
              # Choose the shortest pathed binary, because it's likely to be
              # more desireable than one embedded deep in folder structures.
              Binary.new([bin], "", @outputname).process(first_match)
            end
          end
        end

        def process(tmpfile)
          extract(tmpfile, @dir)
          process_archive
        end

        def extract(tmpfile, dir)
          stdout, stderr, process = call(tmpfile, dir)
          LOG.debug("output") { [stdout.to_s, stderr.to_s, process] }
          [stdout, stderr, process]
        end
      end

      class Tarbz < Base
        class_getter extensions = ["tar.bz2", "tar.bz", "tbz"]

        def call(tmpfile, dir)
          POpen.call("tar", ["-xjf", tmpfile, "-C", dir])
        end
      end

      class Zip < Base
        class_getter extensions = ["zip"]

        def call(tmpfile, dir)
          POpen.call("unzip", ["-d", dir, tmpfile])
        end
      end

      class Targz < Base
        class_getter extensions = ["tar.gz", "tgz"]

        def call(tmpfile, dir)
          POpen.call("tar", ["-xvf", tmpfile, "-C", dir])
        end
      end
    end
  end
end
