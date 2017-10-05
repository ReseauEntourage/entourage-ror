module UpdatedAtSkippable
  def initialize(*)
    @skip_updated_at = false
    super
  end

  def skip_updated_at!
    @skip_updated_at = true
  end

  def should_record_timestamps?
    super && @skip_updated_at == false
  end

  def _update_record(*)
    super.tap do
      @skip_updated_at = false
    end
  end
end
