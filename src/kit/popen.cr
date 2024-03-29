module Kit
  class POpen
    def self.call(bin : String, args : Array(String), env : Process::Env = ENV.to_h, chdir : String = FileUtils.pwd)
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      process = Process.new(bin, args, output: stdout, error: stderr, env: env, chdir: chdir)
      status = process.wait
      [stdout, stderr, process]
    end
  end
end
