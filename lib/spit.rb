class Spit
  %w(area base br col command embed hr img input keygen link meta param source track wbr doctype).
  each do |void_tag|
    define_method(void_tag) { |attributes={}| tag void_tag, attributes }
  end

  %w(a abbr acronym address applet article aside audio b basefont bdi bdo
     bgsound big blink blockquote body button canvas caption center cite code
     colgroup data datalist dd del details dfn dir div dl dt em fieldset
     figcaption figure font footer form frame frameset h1 h2 h3 h4 h5 h6 head
     header hgroup html i iframe ins isindex kbd label legend li listing main
     map mark marquee menu meter nav nobr noframes noscript object ol optgroup
     option output p plaintext pre progress q rp rt ruby s samp script section
     select small spacer span strike strong style sub summary sup table tbody
     td textarea tfoot th thead time title tr tt u ul var video xmp).
  each do |content_tag|
    define_method(content_tag) { |attributes={}, &block| tag  content_tag, attributes, &block }
  end

  %w(text password checkbox radio button submit reset file hidden image datetime
     datetime-local date month time week number range email url search tel color).
  each do |type|
    define_method(type + '_field') { |attributes={}| tag 'input', { type: type }.merge!(attributes) }
  end

  def tag(tag, attributes={}, &block)
    content = block.call.to_s << "</#{tag}>" if block
    "<#{tag}" << attributes.collect { |attr, value| " #{attr}=\"#{value}\""  }.join << ">" << content.to_s
  end
end
