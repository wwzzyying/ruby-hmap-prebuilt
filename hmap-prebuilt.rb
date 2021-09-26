require 'pathname'
require 'json'
require 'fileutils'
require 'xcodeproj'
require 'pp'

require './hmap-prebuilt/hmap_saver.rb'

def hmap_prebuilt(installer)
    puts "[WZY] - start to prebuilt header map"
    
    # 保存结果的 hash
    result_hash = Hash.new()
    
    # 遍历所有头文件, 或者头文件绝对路径
    start_time = Time.now
    installer.pod_targets.each do |target|
        spec_to_absolutePath_hash = target.header_mappings_by_file_accessor
        # 插入到结果 hash
        spec_to_absolutePath_hash.each_value do |headerss|
            headerss.each do |key, headers|
                headers.each do |header|
                    header_short = header.basename
                    key.to_s.include?("/") ? header_long = File.join(key.basename, header_short) : header_long = File.join(key, header_short)
                    result_hash[header_short.to_s] = Hash["prefix" => header.dirname.to_s + "/", "suffix" => header.basename.to_s] # "A.h"
                    result_hash[header_long.to_s] = Hash["prefix" => header.dirname.to_s + "/", "suffix" => header.basename.to_s] # "A/A.h"
                end
            end
        end
    end
    result_json = JSON.pretty_generate(result_hash)
    
    # 保存为 json 文件
    hmap_dir_name = "hmap_prebuilt"
    hmap_name = "all_header_map_prebuilt"
    hmap_prebuilt_dir = File.join(Dir.pwd, "/Pods/#{hmap_dir_name}")
    result_json_path = File.join(Dir.pwd, "/Pods/#{hmap_dir_name}/#{hmap_name}.json")
    result_hmap_path = File.join(Dir.pwd, "/Pods/#{hmap_dir_name}/#{hmap_name}.hmap")
    
    FileUtils.mkdir_p(hmap_prebuilt_dir) unless File.directory?(hmap_prebuilt_dir)
    result_json_file = File.new(result_json_path, "w")
    result_json_file << result_json
    result_json_file.close
    
    # convert json to hmap
    from_file = result_json_path
    to_file = result_hmap_path
    HMapSaver.new_from_buckets(JSON.parse(File.read(from_file))).write_to(to_file)
    File.delete(from_file)
    
    puts "[WZY] - prebuilt header map finish: total time = %.2f s" % (Time.now - start_time).to_f
    
    # 关闭所有组件的 USE_HEADERMAP, 其余手动关闭
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings["USE_HEADERMAP"] = "NO"
        end
    end
    
    # 替换全部 pod 的 HEADER_SEARCH_PATH
    start_time = Time.now
    file_in_path = "\"${PODS_ROOT}/#{hmap_dir_name}/#{hmap_name}.hmap\""
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            next unless config.base_configuration_reference
            xcconfig_path = config.base_configuration_reference.real_path
            build_settings = Hash[*File.read(xcconfig_path).lines.map{ |x| x.split(/\s*=\s*/, 2) }.flatten]
            next unless build_settings.keys.include?("HEADER_SEARCH_PATHS")
            content = File.read(xcconfig_path)
            content = content.gsub(build_settings["HEADER_SEARCH_PATHS"], file_in_path + "\n")
            File.open(xcconfig_path, "w") do |file|
                file.truncate(0) # 清空
                file.puts content # 写入新的内容
            end
        end
    end
    
    puts 'replace_header_search_path_with_hmap_path: total time = %.2f s' % (Time.now - start_time).to_f
    
end
