module Kit
  class POpen
    def self.call(bin, args)
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      process = Process.new(bin, args, output: stdout, error: stderr)
      status = process.wait
      [stdout, stderr, process]
    end
  end
end
