# -*- coding: utf-8 -*- #

require 'rubygems'
require 'bundler'
Bundler.require(:default, :development)

# stdlib
require 'pathname'

class VisualTestApp < Sinatra::Application
  BASE = Pathname.new(__dir__)
  SAMPLES = BASE.join('samples')
  ROOT = BASE.parent.parent

  DEMOS = ROOT.join('lib/rouge/demos')

  def query_string
    env['rack.request.query_string']
  end

  use Rack::Reloader

  configure do
    set :root, BASE
    set :views, BASE.join('templates')
  end

  before do
    Rouge::Lexer.enable_debug!

    theme_class = Rouge::Theme.find(params[:theme] || 'thankful_eyes')
    halt 404 unless theme_class
    @theme = theme_class.new(scope: '.codehilite')

    formatter_opts = { :line_numbers => params[:line_numbers] }
    formatter_opts[:inline_theme] = @theme if params[:inline]

    @formatter = Rouge::Formatters::HTMLLegacy.new(formatter_opts)
  end

  get '/:lexer' do |lexer_name|
    @lexer = Rouge::Lexer.find_fancy("#{lexer_name}?#{query_string}")
    halt 404 unless @lexer
    @sample = File.read(SAMPLES.join(@lexer.class.tag), encoding: 'utf-8')

    @title = "#{@lexer.class.tag} | Visual Test"
    @highlighted = Rouge.highlight(@sample, @lexer, @formatter)

    erb :lexer
  end


  get '/' do
    @samples = DEMOS.entries.sort.reject { |s| s.basename.to_s =~ /^\.|~$/ }
    @samples.map!(&Rouge::Lexer.method(:find))

    erb :index
  end
end
