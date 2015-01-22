require 'mechanize'
require 'openssl'
require 'nokogiri'
require 'json'
require 'sequel'
require 'debugger'
require 'progress_bar'

agent = Mechanize.new
agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

DB = Sequel.connect('mysql://root:luiz123@localhost/uniBrasil')
# DB.run "CREATE TABLE program (id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, code VARCHAR(255) NOT NULL, name VARCHAR(255) NOT NULL, university_id INTEGER NOT NULL)"

program_db = DB[:program]
university_db = DB[:university].where(:status => 0, :sucupira_name => /^[0-9]+/)
total = university_db.count
bar = ProgressBar.new(total)

puts "Total de #{total} universidades seleciondas:"

university_db.each_with_index{|university, index|
	
	page = agent.get("https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf")
	jsessionid = agent.cookies[0].value
	servidorid = agent.cookies[1].value
	utmCookie = ""
	view_state = page.body.scan(/id="javax.faces.ViewState" value="(.+)" auto/)[0][0]
	university_code = university[:id]
	university_name = university[:simple_name]
	university_name.gsub!(/^\s*/, '')

	puts "\n\n\n => #{index+1}/#{total} #{university_code} - #{university_name} "

	resultUni = `curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}; #{utmCookie}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt45%3Ainst%3AvalueId=&form%3Aj_idt45%3Ainst%3Ainput=#{university_name}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt45%3Ainst%3Ainput&javax.faces.partial.event=keyup&javax.faces.partial.execute=form%3Aj_idt45%3Ainst%3Ainput%20form%3Aj_idt45%3Ainst%3Ainput&javax.faces.partial.render=form%3Aj_idt45%3Ainst%3Alistbox&x=334.203125&y=443.1875&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k --silent`
	resultPrograms = `curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}; #{utmCookie}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt45%3Ainst%3AvalueId=&form%3Aj_idt45%3Ainst%3Ainput=#{university_name}&form%3Aj_idt45%3Ainst%3Alistbox=#{university_code}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt45%3Ainst%3Alistbox&javax.faces.partial.event=change&javax.faces.partial.execute=form%3Aj_idt45%3Ainst%3Alistbox%20form%3Aj_idt45%3Ainst&javax.faces.partial.render=form%3Aj_idt45%3Ainst%3Ainst%20form%3Aj_idt45%3Ainst%3AvalueId%20form%3Aj_idt45%3Aprograma&javax.faces.behavior.event=valueChange&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k --silent`

	if resultPrograms.include? 'Programa:'
		resultPrograms = resultPrograms.split('Programa:')
		programs = resultPrograms[1].scan(/<option value="(\d+)">(.*)<\/option>/)

		# set uni whithout resultPrograms
		if programs.size == 0
			university_db.where(:id => university_code).update(:status => 2)
			next 
		end

		
		# insert DB
		programs.each{|program|
			program_db.insert(:code=> program[0].to_i, :name => program[1], :university_id => university_code)
		}

		# set uni whith resultPrograms
		university_db.where(:id => university_code).update(:status => 1)
	end

	bar.increment!
}
