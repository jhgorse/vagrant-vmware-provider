module VagrantPlugins
  module VMwareProvider
    module Driver
      class VMX
        attr_reader :data
      	
        def initialize(filename)
          @filename = filename
          @data = {}
      
          File.open(filename) do |io|
            io.each_line do |line|
              key, value = line.split('=', 2)
              @data[key.strip] = eval(value)
            end
          end
        end
      
        def save(filename=@filename)
          FileUtils.cp(filename, filename + '.bak')
          File.open(filename, 'w') do |f|
            @data.sort_by { |(k,v)| k }.each do |(k,v)|
              f.puts "#{k} = #{v.to_s.inspect}"
            end
          end
        end
      end
    end
  end
end
