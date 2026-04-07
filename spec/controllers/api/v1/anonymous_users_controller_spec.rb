require 'rails_helper'
include CommunityHelper

describe Api::V1::AnonymousUsersController do

  let(:result) { JSON.parse(response.body) }

  describe 'POST create' do
    let!(:user) { AnonymousUserService.create_user $server_community }
    before do
      AnonymousUserService.stub(:create_user) { user }
      post :create
    end

    it { expect(response.status).to eq 201 }

    it { expect(result).to eq(
      'user'=>{
        'id'=>nil,
        'email'=>nil,
        'lang'=>'fr',
        'availability'=>{},
        'display_name'=>nil,
        'display_name'=>nil,
        'first_name'=>nil,
        'last_name'=>nil,
        'roles'=>[],
        'about'=>nil,
        'token'=>user.token,
        'avatar_url'=>nil,
        'user_type'=>'public',
        'partner'=>nil,
        'has_password'=>false,
        'anonymous'=>true,
        'uuid'=>"1_anonymous_#{user.uuid}",
        'stats'=>{
          'tour_count'=>0,
          'encounter_count'=>0,
          'entourage_count'=>0,
          'actions_count' => 0,
          'ask_for_help_creation_count' => 0,
          'contribution_creation_count' => 0,
          'events_count' => 0,
          'outings_count' => 0,
          'neighborhoods_count' => 0,
          'good_waves_participation' => false
        },
        'address'=>nil,
        'address_2'=>nil,
        'firebase_properties'=>{
          'ActionZoneDep'=>'not_set',
          'ActionZoneCP'=>'not_set',
          'Goal' => 'no_set',
          'Interests' => 'none'
        },
        'placeholders'=>['firebase_properties', 'address', 'address_2'],
        'feature_flags'=>{'organization_admin'=>false},
        'engaged'=>false,
        'goal' => nil,
        'phone' => nil,
        'birthday' => nil,
        'birthday_today' => false,
        'unread_count' => 0,
        'interests' => [],
        'involvements' => [],
        'orientations' => [],
        'concerns' => [],
        'gender' => nil,
        'travel_distance' => 10,
        'birthdate' => nil,
        'permissions' => {
          'outing' => {
            'creation' => false
          }
        },
        'created_at' => nil,
      }
    )}
  end
end
