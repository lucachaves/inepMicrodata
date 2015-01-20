# Fazer crawler do sucupira de todas as IES e Programas
# No futuro analisar ano e linha de pesquisa
# https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf

# lista todos as instituições e seus código
require 'mechanize'
require 'openssl'
require 'nokogiri'
require 'json'
require 'sequel'
require 'debugger'
require 'progress_bar'


agent = Mechanize.new
agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

# DB = Sequel.sqlite('uniBrasil.db')
DB = Sequel.connect('mysql://root:luiz123@localhost/uniBrasil')
DB.run "CREATE TABLE program (id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, code VARCHAR(255) NOT NULL, name VARCHAR(255) NOT NULL, university_id INTEGER NOT NULL)"

@programs = DB[:program]
# @universities = DB[:university].where(Sequel.ilike(:name, "%UNIVERSIDADE%"), :status => 0)
# @universities = DB[:university].where(Sequel.ilike(:name, "%UNIVERSIDADE FEDERAL%"), :status => 0)
@universities = DB[:university].where(:status => 0, :name => /^[0-9]+/)

@universities.each_with_index{|university, index|
	# break if index > 10
	
	page = agent.get("https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf")
	jsessionid = agent.cookies[0].value
	servidorid = agent.cookies[1].value
	view_state = page.body.scan(/id="javax.faces.ViewState" value="(.+)" auto/)[0][0]
	
	university_code = university[:id]
	place = university[:name]
	# placeText = place.scan(/(\d+) (.+)/)[0][1]
	# placeSplit = placeText[0..10]
	placeName = place.scan(/(\d+)?(\s?\-?\s?.+)(\s)\(.+\)/)[0][1]

	# puts jsessionid, servidorid, view_state, university_code, place#, placeSplit, placeText, placeName
	puts "\n => #{index+1}/#{@total} #{university_code} - #{place} "

	sleep (5 + index%4)
	`curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt46%3Ainst%3AvalueId=&form%3Aj_idt46%3Ainst%3Ainput=#{placeName}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt46%3Ainst%3Ainput&javax.faces.partial.event=keyup&javax.faces.partial.execute=form%3Aj_idt46%3Ainst%3Ainput%20form%3Aj_idt46%3Ainst%3Ainput&javax.faces.partial.render=form%3Aj_idt46%3Ainst%3Alistbox&x=334.203125&y=443.1875&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k --silent`
	sleep (4 + index%3)
	result = `curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt46%3Ainst%3AvalueId=&form%3Aj_idt46%3Ainst%3Ainput=#{placeName}&form%3Aj_idt46%3Ainst%3Alistbox=#{university_code}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt46%3Ainst%3Alistbox&javax.faces.partial.event=change&javax.faces.partial.execute=form%3Aj_idt46%3Ainst%3Alistbox%20form%3Aj_idt46%3Ainst&javax.faces.partial.render=form%3Aj_idt46%3Ainst%3Ainst%20form%3Aj_idt46%3Ainst%3AvalueId%20form%3Aj_idt46%3Aprograma&javax.faces.behavior.event=valueChange&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k --silent`

	if result.include? 'Programa:'
		result = result.split('Programa:')
		programs = result[1].scan(/<option value="(\d+)">(.*)<\/option>/)

		# puts result[1][0..400]
		puts "\n [Program] "
		if programs.size == 0
			# set uni whithout result
			@universities.where(:id => university_code).update(:status => 2)
			next 
		end

		bar = ProgressBar.new(programs.size)
		
		# insert DB
		programs.each{|program|
			bar.increment!
			@programs.insert(:code=> program[0].to_i, :name => program[1], :university_id => university_code)
		}

		#locate university
		program_code = programs.first[0].to_i
		page = `curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt46%3Ainst%3AvalueId=#{university_code}&form%3Aj_idt46%3Ainst%3Ainput=#{placeName}&form%3Aj_idt46%3Ainst%3Alistbox=#{university_code}&form%3Aj_idt46%3Aj_idt185=#{program_code}&form%3Aconsultar=Consultar&javax.faces.ViewState=#{view_state}' --compressed -k --silent`
		# puts page[0..400]
		puts "\n [Page] "
		city = page.scan(/<span id="form:j_idt98:0:cidade">(.+)<\/span>/)[0][0]
		city = Nokogiri::HTML.parse(city).text
		@universities.where(:id => university_code).update(:city => city)

		# set uni whith result
		@universities.where(:id => university_code).update(:status => 1)
	else
		# puts result
		puts "\n [Falha] "
	end
	
	#locate university
	# if(@universities.where(:id => university_code).all[0][:status] == 1)
	# 	program_code = @programs.where(:university_id => university_code).all[0][:code]
	# 	sleep (5 + index%4)
	# 	`curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt46%3Ainst%3AvalueId=&form%3Aj_idt46%3Ainst%3Ainput=#{placeName}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt46%3Ainst%3Ainput&javax.faces.partial.event=keyup&javax.faces.partial.execute=form%3Aj_idt46%3Ainst%3Ainput%20form%3Aj_idt46%3Ainst%3Ainput&javax.faces.partial.render=form%3Aj_idt46%3Ainst%3Alistbox&x=334.203125&y=443.1875&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k --silent`
	# 	sleep (4 + index%3)
	# 	`curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt46%3Ainst%3AvalueId=&form%3Aj_idt46%3Ainst%3Ainput=#{placeName}&form%3Aj_idt46%3Ainst%3Alistbox=#{university_code}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt46%3Ainst%3Alistbox&javax.faces.partial.event=change&javax.faces.partial.execute=form%3Aj_idt46%3Ainst%3Alistbox%20form%3Aj_idt46%3Ainst&javax.faces.partial.render=form%3Aj_idt46%3Ainst%3Ainst%20form%3Aj_idt46%3Ainst%3AvalueId%20form%3Aj_idt46%3Aprograma&javax.faces.behavior.event=valueChange&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k --silent`
	# 	sleep (4 + index%2)
	# 	page = `curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt46%3Ainst%3AvalueId=#{university_code}&form%3Aj_idt46%3Ainst%3Ainput=#{placeName}&form%3Aj_idt46%3Ainst%3Alistbox=#{university_code}&form%3Aj_idt46%3Aj_idt185=#{program_code}&form%3Aconsultar=Consultar&javax.faces.ViewState=#{view_state}' --compressed -k --silent`
	# 	puts page[0..400]
	# 	city = page.scan(/<span id="form:j_idt98:0:cidade">(.+)<\/span>/)[0][0]
	# 	city = Nokogiri::HTML.parse(city).text
	# 	@universities.where(:id => university_code).update(:city => city)
	# end
}

