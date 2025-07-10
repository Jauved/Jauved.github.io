# _plugins/fix-search-json.rb
# 在 site 写入完毕后，对 search.json 做一次字符串修正
Jekyll::Hooks.register :site, :post_write do |site|
  idx = File.join(site.dest, "assets/js/data/search.json")
  return unless File.exist?(idx)

  text = File.read(idx)
  # 将所有制表符（tab）替换为四个空格，避免 JSON 解析失败
  fixed = text.gsub("\t", "    ")
  # 将所有单反斜杠（\）替换为合法的双反斜杠 (\\)，排除已正确转义的序列
  fixed = fixed.gsub(/\\(?![\\\/\"bfnrtu])/, "\\\\")

  File.write(idx, fixed)
end