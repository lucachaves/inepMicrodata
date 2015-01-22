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
db_mc = Sequel.connect('postgres://postgres:postgres@10.0.1.7/mc-munic')

university_db = DB[:university]
program_db = DB[:program].order(:university_id).distinct(:university_id)
munics = db_mc[:munic]

total = program_db.count
bar = ProgressBar.new(total)

puts "Total de #{total} universidades seleciondas:"

program_db.each_with_index{|program, index|

	page = agent.get("https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf")
	jsessionid = agent.cookies[0].value
	servidorid = agent.cookies[1].value
	utmCookie = ""
	view_state = page.body.scan(/id="javax.faces.ViewState" value="(.+)" auto/)[0][0]
	university = university_db.where(:id => program[:university_id]).first
	university_code = university[:id]
	university_name = university[:simple_name]
	university_name.gsub!(/^\s*/, '')

	`curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}; #{utmCookie}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt45%3Ainst%3AvalueId=&form%3Aj_idt45%3Ainst%3Ainput=#{university_name}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt45%3Ainst%3Ainput&javax.faces.partial.event=keyup&javax.faces.partial.execute=form%3Aj_idt45%3Ainst%3Ainput%20form%3Aj_idt45%3Ainst%3Ainput&javax.faces.partial.render=form%3Aj_idt45%3Ainst%3Alistbox&x=334.203125&y=443.1875&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k --silent`
	`curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}; #{utmCookie}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt45%3Ainst%3AvalueId=&form%3Aj_idt45%3Ainst%3Ainput=#{university_name}&form%3Aj_idt45%3Ainst%3Alistbox=#{university_code}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt45%3Ainst%3Alistbox&javax.faces.partial.event=change&javax.faces.partial.execute=form%3Aj_idt45%3Ainst%3Alistbox%20form%3Aj_idt45%3Ainst&javax.faces.partial.render=form%3Aj_idt45%3Ainst%3Ainst%20form%3Aj_idt45%3Ainst%3AvalueId%20form%3Aj_idt45%3Aprograma&javax.faces.behavior.event=valueChange&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k --silent`

	#locate university
	program_code = program[:code]
	page = `curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}; #{utmCookie}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt45%3Ainst%3AvalueId=#{university_code}&form%3Aj_idt45%3Ainst%3Ainput=#{university_name}&form%3Aj_idt45%3Ainst%3Alistbox=#{university_code}&form%3Aj_idt45%3Aj_idt183=#{program_code}&form%3Aconsultar=Consultar&javax.faces.ViewState=#{view_state}' --compressed -k --silent`
	
	# set location uni
	city = ''
	dom = Nokogiri::HTML(page)
	dom.css('div>table:first-of-type .titulo').each_with_index{|uni, index|
		result = uni.text.gsub(/\s*$/, '')
		puts result
		if Nokogiri::HTML.parse(university_name).text.include? result
			city = dom.css('div>table:first-of-type div:contains("Município:")+div>span')[index].text
			break
		end
	}

	if city != ''
		university_db.where(:id => university_code).update(:city => city)
	# else
	# 	debugger
	end

	bar.increment!
}

result = university_db.where(:status => 1)
bar = ProgressBar.new(result.count)
result.each{|uni|
	city = uni[:city].split(' - ')[0]
	state = uni[:city].split(' - ')[1]
	place = munics.where(:nome => city, :uf => state).first
	university_db.where(:id => uni[:id]).update(
		:latitude => place[:latitude].to_f, 
		:longitude => place[:longitude].to_f
	)
	bar.increment!
}

