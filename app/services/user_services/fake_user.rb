module UserServices
  class FakeUser
    def user_without_tours
      create_user!
    end

    def user_with_tours
      user = create_user!
      TourServices::FakeTour.new(user: user).create_tour!(status: "ongoing")
      TourServices::FakeTour.new(user: user).create_tour!(status: "closed")
      user
    end

    def user_joining_tour(tour:)
      user = create_user!
      JoinRequest.create(joinable: tour, user: user)
      user
    end

    def user_accepted_in_tour(tour:)
      user = create_user!
      join_request = JoinRequest.create(joinable: tour, user: user)
      TourServices::JoinRequestStatus.new(join_request: join_request).accept!
      user
    end

    def user_rejected_of_tour(tour:)
      user = create_user!
      join_request = JoinRequest.create(joinable: tour, user: user)
      TourServices::JoinRequestStatus.new(join_request: join_request).reject!
      user
    end

    def user_quitting_tour(tour:)
      user = create_user!
      join_request = JoinRequest.create(joinable: tour, user: user)
      TourServices::JoinRequestStatus.new(join_request: join_request).cancelled!
      user
    end

    private
    def create_user!
      params = {first_name: ::Faker::Name.first_name,
                last_name: ::Faker::Name.last_name,
                phone: "+336#{99999999-User.count}",
                email: ::Faker::Internet.email}
      organization = Organization.where(name: "Entourage").first
      UserServices::ProUserBuilder.new(params: params, organization: organization).create(sms_code: "123456")
    end
  end
end
