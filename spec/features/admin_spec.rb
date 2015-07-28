describe 'The admin process', :type => :feature do

  before do
    pass = '123abc' * 2
    admin = create :admin, {password: pass}

    visit invitation_groups_url

    expect(page).to have_content('Log in')

    fill_in('admin_email', :with => admin.email)
    fill_in('admin_password', :with => pass)
    click_button 'Log in'
  end

  after do |scenario|
    if scenario.exception
      save_and_open_page
    end
  end


  it 'A signed in admin should be able to access the invitations index page' do
    expect(page).to have_content('Total Invitation Group Count')
  end

  it 'should not let the user edit a confirmed invitation group' do
    invitation_group = create(:invitation_group, :five_guests)
    invitation_group.is_confirmed = true
    invitation_group.save!
    visit edit_invitations_path invitation_group.id
    expect(page).to have_content 'This invitation group has already been confirmed, so you can not edit it!'
  end

  it 'allows an admin to create and inviation' do
    invitation_group = create(:invitation_group, :five_guests)
    guest = invitation_group.guests.sample
    fresh_event = create(:event)
    visit edit_invitations_path invitation_group.id
    node = find "#event_to_guests_#{guest.id}-#{fresh_event.id}"
    node.set(true)
    click_button 'Save'

    invited = guest_invited_to_event? event: fresh_event, guest: guest
    expect(invited).to be(true)
    expect(page).to have_content 'Successfully updated invitation group!'
  end


  it 'allows the admin to delete an invitation' do
    invitation_group = create(:invitation_group, :five_guests)
    inv_to_del = invitation_group.invitations.sample

    visit edit_invitations_path invitation_group.id

    guest = inv_to_del.guest
    event = inv_to_del.event
    node = find "#event_to_guests_#{guest.id}-#{event.id}"
    node.set(false)
    click_button 'Save'

    invited = guest_invited_to_event? event: event, guest: guest
    expect(invited).to be(false)
    expect(page).to have_content 'Successfully updated invitation group!'
  end

  it 'is presented with a set of checkboxes that is consistent with the database' do
    invitation_group = create(:invitation_group, :five_guests)

    visit edit_invitations_path invitation_group.id

    Event.all.each { |event|
      invitation_group.guests.each { |guest|
        node = find("#event_to_guests_#{guest.id}-#{event.id}")
        if guest_invited_to_event? guest: guest, event: event
          expect(node).to be_checked
        else
          expect(node).to_not be_checked
        end
      }
    }

  end


  it 'does not allow admin to create a guest without a first name' do
    invitation_group = create(:invitation_group, :five_guests)
    visit new_invitation_group_guest_path invitation_group.id

    last_name = 'Doe'
    fill_in :guest_last_name, :with => last_name

    click_button 'Create Guest'
    expect(Guest.where(last_name: last_name)).to be_empty
  end

  describe 'when a user is created' do
    before do
      invitation_group = create(:invitation_group, :five_guests)
      visit new_invitation_group_guest_path invitation_group.id

      @first_name = 'John'
      @last_name = 'Doe'
      fill_in :guest_first_name, :with => @first_name
      fill_in :guest_last_name, :with => @last_name
      click_button 'Create Guest'

    end
    it 'creates a user' do
      expect(Guest.where(first_name: @first_name, last_name: @last_name).size).to eq(1)
    end
    it 'take the admin back to the invitations edit page after creating a guest' do
      expect(page).to have_content('Edit Invitations')
    end

  end


  def guest_invited_to_event?(event:, guest:)
    size = Invitation.where(event: event, guest: guest).size
    size > 0
  end

end
