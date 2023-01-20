class ModeratorReadsService
  def initialize(instance:, moderator:)
    @instance = instance
    @user = moderator
  end

  def mark_as_read(at: Time.zone.now)
    moderator_read = @instance.moderator_read_for(user: @user)

    if moderator_read
      moderator_read.update_column(:read_at, at)
    else
      @instance.moderator_reads.create!(user: @user, read_at: at)
    end
  end

  def mark_as_unread
    @instance.moderator_read_for(user: @user).delete
  end
end
