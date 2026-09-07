module Api
  module V1
    # Raised when an authenticated user is not allowed to access/act on a
    # specific resource (e.g. not a member of an entourage/outing/...).
    # Replaces the ~13 near-identical per-controller `UnauthorizedXxx` classes
    # that used to be rescued individually with status: :unauthorized (401),
    # which incorrectly triggers a forced logout on the mobile apps (401 is
    # reserved for actual authentication failures). This is rescued globally
    # in Api::V1::BaseController with status: :forbidden (403).
    class ForbiddenResourceError < StandardError
    end
  end
end
