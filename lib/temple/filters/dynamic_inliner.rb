module Temple
  module Filters
    # Inlines several static/dynamic into a single dynamic.
    class DynamicInliner
      def compile(exp)
        exp.first == :multi ? on_multi(*exp[1..-1]) : exp
      end
      
      def on_multi(*exps)
        res = [:multi]
        curr = nil
        prev = nil
        state = :looking
        
        # We add a noop because we need to do some cleanup at the end too.
        (exps + [:noop]).each do |exp| 
          head, arg = exp

          if head == :dynamic || head == :static
            case state
            when :looking
              # Found a single static/dynamic.  We don't want to turn this
              # into a dynamic yet.  Instead we store it, and if we find
              # another one, we add both then.
              state = :single
              prev = exp
              curr = [:dynamic, '"' + send(head, arg)]
            when :single
              # Yes! We found another one.  Append the content to the current
              # dynamic and add it to the result.
              curr[1] << send(head, arg)
              res << curr
              state = :several
            when :several
              # Yet another dynamic/single.  Just add it now.
              curr[1] << send(head, arg)
            end
          else
            # We need to add the closing quote.
            curr[1] << '"' unless state == :looking
            # If we found a single exp last time, let's add it.
            res << prev if state == :single
            # Compile the current exp (unless it's the noop)
            res << compile(exp) unless head == :noop
            # Now we're looking for more!
            state = :looking
          end
        end
        
        res
      end
    
      def static(str)
        str.inspect[1..-2]
      end
      
      def dynamic(str)
        '#{%s}' % str
      end
    end
  end
end