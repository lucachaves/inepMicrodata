# Fazer crawler do sucupira de todas as IES e Programas
# No futuro analisar ano e linha de pesquisa
# https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf

# lista todos as instituições e seus código
require 'mechanize'
require 'openssl'
require 'nokogiri'
require 'json'
require_relative 'placesSucupira.rb'


@programs = {}
@count = 0
agent = Mechanize.new
agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

@places.each{|code, place|
	@count += 1
	break if @count > 4
	
	page = agent.get("https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf")
	# agent.cookies.to_s
	jsessionid = agent.cookies[0].value
	servidorid = agent.cookies[1].value
	view_state = page.body.scan(/id="javax.faces.ViewState" value="(.+)" auto/)[0][0]
	
	# jsessionid = 'kYjBJZjwhBTglERD43KYpxgD.sucupira-75'
	# view_state = '-9211734103746304770:-7575146433863366975'

	place = Nokogiri::HTML.parse(place).text
	placeText = place.scan(/(\d+) (.+)/)[0][1]
	placeSplit = placeText[0..10]
	placeName = place.scan(/(\d+) (.+)(\s)\(.+\)/)[0][1]

	puts jsessionid, servidorid, view_state, code, place#, placeSplit, placeText, placeName
	sleep (6 + @count%2)
	`curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt46%3Ainst%3AvalueId=&form%3Aj_idt46%3Ainst%3Ainput=#{placeName}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt46%3Ainst%3Ainput&javax.faces.partial.event=keyup&javax.faces.partial.execute=form%3Aj_idt46%3Ainst%3Ainput%20form%3Aj_idt46%3Ainst%3Ainput&javax.faces.partial.render=form%3Aj_idt46%3Ainst%3Alistbox&x=334.203125&y=443.1875&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k`
	# sleep 2
	# `curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt46%3Ainst%3AvalueId=&form%3Aj_idt46%3Ainst%3Ainput=#{placeName}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt46%3Ainst%3Ainput&javax.faces.partial.event=keyup&javax.faces.partial.execute=form%3Aj_idt46%3Ainst%3Ainput%20form%3Aj_idt46%3Ainst%3Ainput&javax.faces.partial.render=form%3Aj_idt46%3Ainst%3Alistbox&x=334.203125&y=443.1875&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k`
	sleep (4 + @count%3)
	result = `curl 'https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'Cookie: JSESSIONID=#{jsessionid}; SERVERID=#{servidorid}' -H 'Origin: https://sucupira.capes.gov.br' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Faces-Request: partial/ajax' -H 'Content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'Accept: */*' -H 'Referer: https://sucupira.capes.gov.br/sucupira/public/consultas/coleta/dadosCadastrais/dadosCadastraisPublico.jsf' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36' -H 'Connection: keep-alive' --data 'form=form&form%3Aj_idt46%3Ainst%3AvalueId=&form%3Aj_idt46%3Ainst%3Ainput=#{placeName}&form%3Aj_idt46%3Ainst%3Alistbox=#{code}&javax.faces.ViewState=#{view_state}&javax.faces.source=form%3Aj_idt46%3Ainst%3Alistbox&javax.faces.partial.event=change&javax.faces.partial.execute=form%3Aj_idt46%3Ainst%3Alistbox%20form%3Aj_idt46%3Ainst&javax.faces.partial.render=form%3Aj_idt46%3Ainst%3Ainst%20form%3Aj_idt46%3Ainst%3AvalueId%20form%3Aj_idt46%3Aprograma&javax.faces.behavior.event=valueChange&AJAX%3AEVENTS_COUNT=1&javax.faces.partial.ajax=true' --compressed -k`
	

	if result.include? 'Programa:'
		result = result.split('Programa:')
		puts result[1][0..400]
		@programs[code] = result[1].scan(/<option value="(\d+)">(.*)<\/option>/)
	else
		puts result
	end
}

# puts JSON.pretty_generate(@programs)