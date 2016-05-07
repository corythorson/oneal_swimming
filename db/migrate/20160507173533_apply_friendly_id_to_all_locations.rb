class ApplyFriendlyIdToAllLocations < ActiveRecord::Migration
  def up
    Location.find_each(&:save)
  end

  def down
    say 'Nothing to revert'
  end
end
