require 'spec_helper'
  VOID_ELEMENTS    = %w(area base br col command embed hr img input keygen link meta param source track wbr doctype)
  CONTENT_ELEMENTS = %w(a abbr acronym address applet article aside audio b basefont bdi bdo
     bgsound big blink blockquote body button canvas caption center cite code
     colgroup data datalist dd del details dfn dir div dl dt em fieldset
     figcaption figure font footer form frame frameset h1 h2 h3 h4 h5 h6 head
     header hgroup html i iframe ins isindex kbd label legend li listing main
     map mark marquee menu meter nav nobr noframes noscript object ol optgroup
     option output p plaintext pre progress q rp rt ruby s samp script section
     select small spacer span strike strong style sub summary sup table tbody
     td textarea tfoot th thead time title tr tt u ul var video xmp)
  INPUT_TYPES =  %w(text password checkbox radio button submit reset file hidden image datetime
     datetime-local date month time week number range email url search tel color)

describe Spit do
  let(:spit) { Spit.new }
  describe 'void_elements' do
    VOID_ELEMENTS.each do |elem|
      it "knows how to spit a #{elem}" do
        spit.must_respond_to elem.to_sym
      end

      it "generates an #{elem}" do
        spit.send(elem).must_equal "<#{elem}>"
      end
    end
  end

  describe 'content elements' do
    CONTENT_ELEMENTS.each do |elem|
      it "knows how to spit a #{elem}" do
        spit.must_respond_to elem
      end

      it "generates an empty #{elem}" do
        spit.send(elem, {}, &Proc.new{}).must_equal "<#{elem}></#{elem}>"
      end

      it "generates a #{elem} with contents" do
        spit.send(elem, {}, &Proc.new {'content'}).must_equal "<#{elem}>content</#{elem}>"
      end
    end
  end

  describe 'input fields' do
    INPUT_TYPES.each do |type|
      message = type + '_field'
      it "knows how to spit a #{type} field" do
        spit.must_respond_to message
      end

      it "generates #{type} field" do
        spit.send(message).must_equal "<input type=\"#{type}\">"
      end

      it "merges attributes with the type=#{type} attribute" do
        spit.send(message, id: '1234', class:'a-class').must_equal "<input type=\"#{type}\" id=\"1234\" class=\"a-class\">"
      end
    end
  end

  it 'can spit its own spits' do
    spit.div do
      spit.ul do
        spit.li do
          spit.a do
            "so spitted..."
          end
        end <<
        spit.li do
          "it's disgusting"
        end
      end
    end.
    must_equal "<div><ul><li><a>so spitted...</a></li><li>it's disgusting</li></ul></div>"
  end

  it 'can spit declaration context bound values' do
    class Spitter
      def initialize
        @var = "variable"
      end

      def spit
        Spit.new.div do
          @var
        end
      end
    end

    Spitter.new.spit.must_equal "<div>variable</div>"
  end
end
