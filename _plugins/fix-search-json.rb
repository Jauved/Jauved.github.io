# _plugins/fix-search-json.rb
# 在 site 写入完毕后，对 search.json 做一次字段级别修正，并验证读写生效
require 'json'

Jekyll::Hooks.register :site, :post_write do |site|
  path = site.in_dest_dir('assets', 'js', 'data', 'search.json')
  return unless File.exist?(path)

  # 读取文件并移除 BOM
  raw = File.binread(path)
  raw = raw.bytes.drop(3).pack("C*") if raw.bytes.first(3) == [0xEF, 0xBB, 0xBF]
  text = raw.force_encoding('utf-8')

  # 解析 JSON
  data = JSON.parse(text)

  # 遍历并清洗 content 字段中的所有反斜杠
  data.each do |item|
    next unless item['content'].is_a?(String)
    # 清除 content 值中的反斜杠，不影响合法 JSON 转义
    item['content'] = item['content'].delete('\\')
  end

  # 将修改后的结构写回文件
  File.open(path, 'wb') do |f|
    f.write(JSON.generate(data))
  end

  Jekyll.logger.info "FixSearchJSON:", "Repaired #{path}"
end