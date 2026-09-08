module Api
  module V1
    # Generic, cross-resource error codes returned in the `error.code` field
    # of API error responses (see Api::V1::BaseController#render_error).
    #
    # Resource-specific codes (USER_NOT_FOUND, INVALID_PHONE_FORMAT, ...) stay
    # defined inline where they are raised - only the codes shared across many
    # controllers are centralized here to avoid typos/duplication.
    module ErrorCodes
      UNAUTHORIZED = 'UNAUTHORIZED'
      FORBIDDEN = 'FORBIDDEN'
      NOT_FOUND = 'NOT_FOUND'
      VALIDATION_ERROR = 'VALIDATION_ERROR'
      PARAMETER_MISSING = 'PARAMETER_MISSING'
      INTERNAL_ERROR = 'INTERNAL_ERROR'
    end
  end
end
