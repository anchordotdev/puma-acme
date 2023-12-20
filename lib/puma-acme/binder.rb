require 'puma/binder'

module Puma
 class Binder 
   def parse_with_before_hooks(...)
     @before_parse_hooks&.each(&:call)

     original_parse(...)
   end

   alias_method :original_parse, :parse
   alias_method :parse, :parse_with_before_hooks

   def before_parse_hook(&hook)
     (@before_parse_hooks ||= []) << hook
   end
 end
end
