#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end	

# before вызывается каждый раз при перезагрузке
before do
	# инициализация БД
	init_db
end	

configure do
	# инициализация БД
	init_db
	# создает таблицу если таблица не существует
	@db.execute 'CREATE TABLE IF NOT EXISTS
		Posts
		(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			created_date DATE,
			author TEXT,
			content TEXT
		)'

		@db.execute 'CREATE TABLE IF NOT EXISTS
		Comments
		(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			created_date DATE,
			content TEXT,
			post_id Integer
		)'
end	

get '/' do
	# выбираем список постов из БД

	@results = @db.execute 'select * from Posts order by id desc'

	erb :index
end

# обработчик get-запроса /new
# (браузер получает таблицу с сервера)
get '/new' do
  erb :new
end

# обработчик post-запроса /new
# (браузер отправляет данные на сервер)
post '/new' do
	# получаем переменную из post-запроса
	author = params[:author]
  content = params[:content]

	if author.length <= 0
		@error = 'Type name author'
		return erb :new
	end	

	if content.length <= 0
		@error = 'Type post text'
		return erb :new
	end	

	# сохранение данных в БД
	@db.execute 'insert into Posts (author, content, created_date) values (?, ?, datetime())', [author, content]

	# перенаправление на главную страницу
	redirect to '/'
end

# вывод информации о посте
get '/details/:post_id' do
	
	# получаем переменную из url'a
	post_id = params[:post_id]

	# получаем список постов
	# (у нас будет только один пост)
	results = @db.execute 'select * from Posts where id = ?', [post_id]

	# выбираем этот один пост в переменную @row
	@row = results[0]

	# выбираем комментарии для нашего поста
	@comments = @db.execute 'select * from Comments where post_id = ? order by id', [post_id]

	# возвращаем представление details.erb
	erb :details
end	

# обработчик post-запроса /details/...
# (браузер отправляет данные на сервер, мы их принимаем)

post '/details/:post_id' do

	# получаем переменную из url'a
	post_id = params[:post_id]

	# получаем переменную из post-запроса
  content = params[:content]

	# проверяем заполненность комментария
	if content.length <= 0
		@error = 'Type comment text'
		redirect to ('/details/' + post_id)	
	end	

	# сохранение данных в БД
	@db.execute 'insert into Comments 
		(
			content, 
			created_date, 
			post_id
		) 
			values 
		(
			?, 
			datetime(),
			?
		)', [content, post_id]

	# перенаправление на главную страницу
	redirect to ('/details/' + post_id)
end	