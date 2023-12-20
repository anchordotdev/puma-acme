require 'puma/binder'

module Puma
 class Binder 
   def parse_with_after_hooks(...)
     original_parse(...)

     @after_parse_hooks&.each(&:call)
   end

   alias_method :original_parse, :parse
   alias_method :parse, :parse_with_after_hooks

   def after_parse_hook(&hook)
     (@after_parse_hooks ||= []) << hook
   end
 end
end
