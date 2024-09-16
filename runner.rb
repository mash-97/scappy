categories = {
  "Data Science & Analytics" => 531770282580668420,

  "Engineering & Architecture"  => 531770282584862722,

  "IT & Networking" => 531770282580668419,

  "Web, Mobile & Software Dev" => 531770282580668418
}

categories.each do |k, v|
  puts("start process for: #{k}")
  system("ruby scappy.rb scrap --start_page 1 --end_page 2 --category #{v} --output '#{k}.xlsx'")
  puts("finished process for: #{k}")
  puts
end
