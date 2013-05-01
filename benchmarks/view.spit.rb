SpitTemplate = Proc.new do |header, item|
  s = Spit.new
  s.html do
    s.head do
      s.meta(title: 'Simple Benchmark')
    end
    s.body do
      s.h1(header) <<
      unless item.empty?
        s.ul do
          item.inject('') do |list, i|
            list <<
            if(i[:current])
              s.li do
                s.strong do
                  i[:name]
                end
              end
            else
              s.li do
                s.a(href: i[:url]) do
                  i[:name]
                end
              end
            end
          end
        end
      else
        s.p do
          "The list is empty"
        end
      end
    end
  end
end
