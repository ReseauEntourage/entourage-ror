module Experimental
  module Memoize
    def memoize var_name
      var_name = "@#{var_name}"

      return yield unless memoize?

      if instance_variable_defined? var_name
        instance_variable_get var_name
      else
        instance_variable_set var_name, yield
      end
    end

    def memoize?
      true
    end
  end
end
