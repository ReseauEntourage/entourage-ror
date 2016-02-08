module UserServices
  class FakeUser
    def create_user!
      params = {first_name: Faker::Name.first_name,
                last_name: Faker::Name.last_name,
                phone: "+336#{99999999-User.count}",
                email: Faker::Internet.email}
      organization = : Organisation.where(name: "Entourage").first
      UserServices::ProUserBuilder.new(params: params, organization: organization).create
    end

    def user_with_tours
      user = create_user!
      TourServices::FakeTour.new(user: user).create_tour!(status: "ongoing")
      TourServices::FakeTour.new(user: user).create_tour!(status: "closed")
    end

    def user_joining_tour(tour:)
      user = create_user!
      ToursUser.create(tour: tour, user: user)
      user
    end

    def user_accepted_in_tour(tour:)
      user = create_user!
      tours_user = ToursUser.create(tour: tour, user: user)
      TourServices::ToursUserStatus.new(tours_user: tours_user).accept!
      user
    end

    def user_rejected_of_tour(tour:)
      user = create_user!
      tours_user = ToursUser.create(tour: tour, user: user)
      TourServices::ToursUserStatus.new(tours_user: tours_user).reject!
      user
    end
  end
end