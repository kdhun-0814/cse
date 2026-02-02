require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 1. Find the 'Runner' group
group = project.main_group['Runner']
if group.nil?
  puts "Error: Could not find 'Runner' group"
  # Try iterating if simple access fails
  group = project.main_group.groups.find { |g| g.display_name == 'Runner' }
end

if group.nil?
  puts "Still could not find 'Runner' group. Available groups: #{project.main_group.groups.map(&:display_name)}"
  exit 1
end

# 2. Check if file is already in the group
file_name = 'GoogleService-Info.plist'
file_ref = group.find_file_by_path(file_name)

if file_ref
  puts "File reference already exists in group."
else
  # Add file to group
  file_ref = group.new_reference(file_name)
  puts "Added file reference to group."
end

# 3. Add to 'Runner' target's resources build phase
target = project.targets.find { |t| t.name == 'Runner' }
if target.nil?
  puts "Error: Could not find 'Runner' target"
  exit 1
end

resources_phase = target.resources_build_phase
build_file = resources_phase.files.find { |f| f.file_ref == file_ref }

if build_file
  puts "File is already in Copy Bundle Resources phase."
else
  resources_phase.add_file_reference(file_ref)
  puts "Added file to Copy Bundle Resources phase."
end

project.save
puts "Project saved successfully."
