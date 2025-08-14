# _plugins/fix-search-json.rb
# 在 site 写入完毕后，对 search.json 做一次字符串修正，并验证读写生效
Jekyll::Hooks.register :site, :post_write do |site|
  path = site.in_dest_dir('assets', 'js', 'data', 'search.json')
  Jekyll.logger.info "FixSearchJSON:", "Checking #{path}"
  return unless File.exist?(path)

  # 读取文件并确保 utf-8 编码
  raw = File.binread(path)
  # 检查并移除 UTF-8 BOM
  if raw.bytes.first(3) == [0xEF, 0xBB, 0xBF]
    Jekyll.logger.info "FixSearchJSON:", "Detected BOM, will remove"
    raw = raw.bytes.drop(3).pack("C*")
  end
  text = raw.force_encoding('utf-8')

  # 打印前两行示例，用于调试匹配
  snippet_before = text.lines.first(2).join
  Jekyll.logger.info "FixSearchJSON:", "Snippet before: #{snippet_before.inspect}"

  # 匹配单个反斜杠，后面不是 转义字符 或 JSON 专用转义
  # slash_pattern = /\\(?=[^\\\/\"bfnrtu])/
  # slash_pattern = /\\(?=[^\\\/\"fnrtu])/

  # 替换操作：Tab 转空格，未转义的反斜杠加转义
  new_text = text.gsub("\t", "    ")
  # new_text = new_text.gsub(slash_pattern) { "\\\\" }
  # new_text = new_text.gsub(slash_pattern) { "" }
  new_text = new_text.gsub(/("content"\s*:\s*")((?:[^"\\]|\\.)*?)(")/) do
    key = Regexp.last_match(1)  # "content":
    val = Regexp.last_match(2)  # 内容
    endq = Regexp.last_match(3) # 结束引号
    cleaned_val = val.gsub("\\", "")
    "#{key}#{cleaned_val}#{endq}"
  end

  # 写入并验证
  File.open(path, 'wb') { |f| f.write(new_text) }
  verify = File.binread(path).force_encoding('utf-8')
  snippet_after = verify.lines.first(2).join
  Jekyll.logger.info "FixSearchJSON:", "Snippet after: #{snippet_after.inspect}"

  Jekyll.logger.info "FixSearchJSON:", "Repaired #{path}"
end