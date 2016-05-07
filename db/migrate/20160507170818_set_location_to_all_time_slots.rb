class SetLocationToAllTimeSlots < ActiveRecord::Migration
  def up
    location = Location.where(name: 'Highland Pool').first_or_create!({
      street_address: '10196 Hidden Pond Dr',
      city: 'Highland',
      state: 'UT',
      zip_code: '84003'
    })
    TimeSlot.update_all(location_id: location.id)
  end

  def down
    say 'Nothing to revert'
  end
end
