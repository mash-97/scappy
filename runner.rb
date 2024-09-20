categories = {
  # "Data Science & Analytics" => 531770282580668420,

  # "Engineering & Architecture"  => 531770282584862722,

  # "IT & Networking" => 531770282580668419,
  "Sales & Marketing" => 531770282580668422,

  "Web, Mobile & Software Dev" => 531770282580668418
}
if ARGV[0]=="help" then
  puts('> Start of the runner script')
  puts('> Start Page: #{ARGV[0]}')
  puts('> End Page: #{ARGV[1]}')
  puts('> Per Page: #{ARGV[2]}')
  puts('> Batch Size: #{ARGV[3]}')
  puts('> Sheet Name: #{ARGV[4]}')
  puts()
  puts()
  exit(0)
end

puts("> Start of the runner script")
puts("> Start Page: #{ARGV[0]}")
puts("> End Page: #{ARGV[1]}")
puts("> Per Page: #{ARGV[2]}")
puts("> Batch Size: #{ARGV[3]}")
puts("> Sheet Name: #{ARGV[4]}")
puts()
puts()


s = Time.now
categories.each do |k, v|
  puts(">> start process for: #{k}")
  system(%{ruby scappy.rb scrap --start_page #{ARGV[0]} --end_page #{ARGV[1]} --per_page #{ARGV[2]} --category #{v} --output "#{k}.xlsx" --batch_size #{ARGV[3]} --sheet_name "#{ARGV[4]}"})
  puts(">> finished process for: #{k}")
  puts
end
e = Time.now
puts("> End of the runner script")
puts("> Execution Time: #{(e-s).round(3)} seconds")
