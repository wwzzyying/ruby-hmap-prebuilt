def glob_header
    current_dir = Dir.pwd
    result_hash = Hash.new()
    Dir.glob("#{current_dir}/[!Pods/]**/*.h").each { | header_file |
        dirname = File.dirname(header_file)
        basename = File.basename(header_file)
        result_hash[basename] = Hash["prefix" => dirname, "suffix" => basename]
        result_hash[File.join(dirname.split("/").last, basename)] = Hash["prefix" => dirname, "suffix" => basename]
    }
    result_hash
end
