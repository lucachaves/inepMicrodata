require 'sequel'
require 'progress_bar'

db_inep = Sequel.connect('postgres://postgres:postgres@10.0.1.7/inep-curso')
db_mc = Sequel.connect('postgres://postgres:postgres@10.0.1.7/mc-munic')

# read all curso
cursos = db_inep.from(:curso)
munics = db_mc.from(:munic)

result = cursos.all
bar = ProgressBar.new(result.count)
result.each{|curso|
	id = curso[:id]

	# insert sigla

	# insert nome ascii
	city = curso[:no_municipio_curso]
	city = city.tr(
		"ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž",
		"AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz"
	)
	cursos.
			where(id: id).
			update(no_municipio_curso_ascii: city.downcase)

	# # get cidade and uf, then search latlon from mc-munic
	# munic = munics.where(nome: curso[:no_municipio_curso], uf: curso[:sgl_uf_curso])
	# if munic.count > 0
	# 	# insert latlon
	# 	cursos.
	# 		where(id: id).
	# 		update(latitude: munic.all[0][:latitude].to_f, longitude: munic.all[0][:longitude].to_f)
	# end

	bar.increment!
}

