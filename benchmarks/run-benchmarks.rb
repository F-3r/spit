#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'), File.dirname(__FILE__))

require 'slim'
require 'context'

require 'benchmark'
require 'tilt'
require 'erubis'
require 'erb'
require 'haml'
require 'mote'
require 'spit'

require './view.spit'

class SpitBenchmarks
  def initialize(iterations)
    @iterations = (iterations || 1000).to_i
    @benches    = []

    @erb_code  = File.read(File.dirname(__FILE__) + '/view.erb')
    @haml_code = File.read(File.dirname(__FILE__) + '/view.haml')
    @slim_code = File.read(File.dirname(__FILE__) + '/view.slim')
    @mote_code = File.read(File.dirname(__FILE__) + '/view.mote')

    init_compiled_benches
    init_tilt_benches
    init_cached_benches
    init_parsing_benches
  end

  def init_compiled_benches
    erb         = ERB.new(@erb_code)
    erubis      = Erubis::Eruby.new(@erb_code)
    fast_erubis = Erubis::FastEruby.new(@erb_code)
    haml_pretty = Haml::Engine.new(@haml_code, :format => :html5)
    haml_ugly   = Haml::Engine.new(@haml_code, :format => :html5, :ugly => true)
    mote = Mote.parse(@mote_code)

    context  = Context.new
    mote_params = {header: context.header, item: context.item}

    haml_pretty.def_method(context, :run_haml_pretty)
    haml_ugly.def_method(context, :run_haml_ugly)
    context.instance_eval %{
      def run_erb; #{erb.src}; end
      def run_erubis; #{erubis.src}; end
      def run_temple_erb; #{Temple::ERB::Engine.new.call @erb_code}; end
      def run_fast_erubis; #{fast_erubis.src}; end
      def run_slim_pretty; #{Slim::Engine.new(:pretty => true).call @slim_code}; end
      def run_slim_ugly; #{Slim::Engine.new.call @slim_code}; end
    }

    bench('(1) erb')         { context.run_erb }
    bench('(1) erubis')      { context.run_erubis }
    bench('(1) fast erubis') { context.run_fast_erubis }
    bench('(1) temple erb')  { context.run_temple_erb }
    bench('(1) slim pretty') { context.run_slim_pretty }
    bench('(1) slim ugly')   { context.run_slim_ugly }
    bench('(1) haml pretty') { context.run_haml_pretty }
    bench('(1) haml ugly')   { context.run_haml_ugly }
    bench('(1) mote')        { mote.call(mote_params) }
    bench('(1) spit')        { SpitTemplate.call(context.header, context.item) }
  end

  def init_tilt_benches
    tilt_erb        = Tilt::ERBTemplate.new { @erb_code }
    tilt_erubis     = Tilt::ErubisTemplate.new { @erb_code }
    tilt_temple_erb = Temple::ERB::Template.new { @erb_code }
    tilt_haml_pretty= Tilt::HamlTemplate.new(:format => :html5){ @haml_code }
    tilt_haml_ugly  = Tilt::HamlTemplate.new(:format => :html5, :ugly => true){ @haml_code }
    tilt_slim_pretty= Slim::Template.new(:pretty => true) { @slim_code }
    tilt_slim_ugly  = Slim::Template.new { @slim_code }

    context  = Context.new

    bench('(2) erb')         { tilt_erb.render(context) }
    bench('(2) erubis')      { tilt_erubis.render(context) }
    bench('(2) temple erb')  { tilt_temple_erb.render(context) }
    bench('(2) slim pretty') { tilt_slim_pretty.render(context) }
    bench('(2) slim ugly')   { tilt_slim_ugly.render(context) }
    bench('(2) haml pretty') { tilt_haml_pretty.render(context) }
    bench('(2) haml ugly')   { tilt_haml_ugly.render(context) }
  end

  def init_cached_benches
    context  = Context.new
    context_binding = context.instance_eval { binding }

    mote_params = { header: context.header, item: context.item }

    erb         = ERB.new(@erb_code)
    erubis      = Erubis::Eruby.new(@erb_code)
    fast_erubis = Erubis::FastEruby.new(@erb_code)
    temple_erb  = Temple::ERB::Template.new { @erb_code }
    haml_pretty = Haml::Engine.new(@haml_code, :format => :html5)
    haml_ugly   = Haml::Engine.new(@haml_code, :format => :html5, :ugly => true)
    slim_pretty = Slim::Template.new(:pretty => true) { @slim_code }
    slim_ugly   = Slim::Template.new { @slim_code }
    mote        = Mote.parse(@mote_code)

    bench('(3) erb')         { erb.result(context_binding) }
    bench('(3) erubis')      { erubis.result(context_binding) }
    bench('(3) fast erubis') { fast_erubis.result(context_binding) }
    bench('(3) temple erb')  { temple_erb.render(context) }
    bench('(3) slim pretty') { slim_pretty.render(context) }
    bench('(3) slim ugly')   { slim_ugly.render(context) }
    bench('(3) haml pretty') { haml_pretty.render(context) }
    bench('(3) haml ugly')   { haml_ugly.render(context) }
    bench('(3) mote')        { mote.call(mote_params) }
    bench('(3) spit')        { SpitTemplate.call(context.header, context.item) }
  end

  def init_parsing_benches
    context  = Context.new
    context_binding = context.instance_eval { binding }
    mote_params = {header: context.header, item: context.item}

    bench('(4) erb')         { ERB.new(@erb_code).result(context_binding) }
    bench('(4) erubis')      { Erubis::Eruby.new(@erb_code).result(context_binding) }
    bench('(4) fast erubis') { Erubis::FastEruby.new(@erb_code).result(context_binding) }
    bench('(4) temple erb')  { Temple::ERB::Template.new { @erb_code }.render(context) }
    bench('(4) slim pretty') { Slim::Template.new(:pretty => true) { @slim_code }.render(context) }
    bench('(4) slim ugly')   { Slim::Template.new { @slim_code }.render(context) }
    bench('(4) haml pretty') { Haml::Engine.new(@haml_code, :format => :html5).render(context) }
    bench('(4) haml ugly')   { Haml::Engine.new(@haml_code, :format => :html5, :ugly => true).render(context) }
    bench('(4) mote')        { Mote.parse(@mote_code).call(mote_params) }
    bench('(4) spit')        { SpitTemplate.call(context.header, context.item) }
  end

  def run
    puts "#{@iterations} Iterations"
    Benchmark.bmbm do |x|
      @benches.each do |name, block|
        x.report name.to_s do
          @iterations.to_i.times { block.call }
        end
      end
    end
    puts "
(1) Compiled benchmark. Template is parsed before the benchmark and
    generated ruby code is compiled into a method.
    This is the fastest evaluation strategy because it benchmarks
    pure execution speed of the generated ruby code.

(2) Compiled Tilt benchmark. Template is compiled with Tilt, which gives a more
    accurate result of the performance in production mode in frameworks like
    Sinatra, Ramaze and Camping. (Rails still uses its own template
    compilation.)

(3) Cached benchmark. Template is parsed before the benchmark.
    The ruby code generated by the template engine might be evaluated every time.
    This benchmark uses the standard API of the template engine.

(4) Parsing benchmark. Template is parsed every time.
    This is not the recommended way to use the template engine
    and Slim is not optimized for it. Activate this benchmark with 'rake bench slow=1'.

Temple ERB is the ERB implementation using the Temple framework. It shows the
overhead added by the Temple framework compared to ERB.
"
  end

  def bench(name, &block)
    @benches.push([name, block])
  end
end

SpitBenchmarks.new(ENV['iterations']).run
