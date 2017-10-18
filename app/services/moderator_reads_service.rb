class ModeratorReadsService
  def initialize(entourage:, moderator:)
    @entourage = entourage
    @user = moderator
  end

  def mark_as_read(at: Time.zone.now)
    moderator_read = @entourage.moderator_read_for(user: @user)

    if moderator_read
      moderator_read.update_column(:read_at, at)
    else
      @entourage.moderator_reads.create!(user: @user, read_at: at)
    end
  end

  def mark_as_unread
    @entourage.moderator_read_for(user: @user).delete
  end
end
