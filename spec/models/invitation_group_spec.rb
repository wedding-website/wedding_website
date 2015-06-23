require 'rails_helper'

RSpec.describe InvitationGroup, :type => :model do

  it 'confirmed invitation group can\'t have added guests' do
    invitation_group = create :invitation_group, is_confirmed: true
    invitation_group.guests << create(:guest)
    expect { invitation_group.save! }.to raise_error
  end

  it "has code" do
    invitation_group = build :invitation_group
    expect(invitation_group.code).to be_instance_of(String)
  end

  it "has is_confirmed" do
    invitation_group = build :invitation_group
    invitation_group.is_confirmed
  end

  it "has confirmed that can't be nil" do
    expect { create(:invitation_group, {is_confirmed: nil}) }.to raise_error ActiveRecord::RecordInvalid
  end

  it "can not be updated once confimed" do
    ig = create(:invitation_group)
    ig.is_confirmed = true
    ig.save!

    ig.code = "changed value"
    expect {ig.save!}.to raise_error ActiveRecord::ReadOnlyRecord
  end

  it "must have code" do
    expect { create(:invitation_group, {code: ''}) }.to raise_error ActiveRecord::RecordInvalid
  end

  it "has_attendees must return false there are no guests" do
    invitation_group = create(:invitation_group, :four_invitations)
    expect(invitation_group.has_attendees).to be(false)
  end

  it "has_attendees must return false there are no guests and no invitations" do
    invitation_group = create(:invitation_group)
    expect(invitation_group.has_attendees).to be(false)
  end

  it "has_attendees must return true there are guests" do
    invitation_group = create(:invitation_group, :four_invitations)
    invitation = invitation_group.invitations.first()
    invitation.is_accepted = true
    invitation.guest= create(:guest)
    invitation_group.save!
    expect(invitation_group.has_attendees).to be(true)
  end

  it "must not return duplicates when calling accepted_attendees" do
    invitation_group = create(:invitation_group, :four_invitations)
    guest = create(:guest)
    invitation_group.invitations.each { |invitation|
      invitation.is_accepted = true
      invitation.guest= guest
    }
    invitation_group.save!
    accepted_attendees = invitation_group.accepted_attendees
    expect(accepted_attendees.size).to equal(accepted_attendees.uniq.size)
  end

  it "must delete associated invitations on delete" do
    invitation_group = create(:invitation_group)
    invitations = invitation_group.invitations
    invitation_group.destroy
    invitations.each { |invitation|
      expect(Invitation.exists?(invitation)).to be(false)
    }

  end

  it "can have code" do
    create(:invitation_group, {code: 'foobar'})
  end

end
