-- examen tema 1 parte 2 
-- consulta 1 
/*
- Informar razón social, cuit, dirección, barrio, localidad de aquellos proveedores que no
registran al momento de efectuar la consulta ningún tipo de producto. Debe emplear un
procedimiento almacenado para resolver este ejercicio. A su vez, tenga en cuenta que no debe
utilizar ningún tipo de palabra reservada asociadas con los JOINS. Los encabezados de las
columnas deben ser: Razón Social, Cuit, Dirección, Barrio, Localidad, según la columna que
corresponda.
*/

create proc P_ProveedoresSinArticulos
as
select cuit_Prov,razonSocial_Prov,direccion_Prov,(select descripcion_Loc from LOCALIDADES where codPostal_Loc=codLocalidad_Prov)as localidad,(select descripcion_Barr from barrios where codBarrio_Barr=codBarrio_Prov)as Barrio from PROVEEDORES  where cod_Prov not in (select codProv_Art from ARTICULOS);
exec P_ProveedoresSinArticulos

/*
### Consulta 2
- Informar nombre completo, dni, domicilio, barrio, localidad, género y edad al momento
de efectuar la consulta de aquellos clientes que tengan registrados la menor cantidad de
números telefónicos y pertenezcan al sexo femenino. Debe emplear un procedimiento
almacenado. Como sugerencia para la resolución de este punto, es conveniente añadir un
campo adicional en la tabla que le resulte más apropiada a modo de poder llevar adelante la
consulta. Ejecute el procedimiento almacenado y posterior a dicha ejecución, la tabla que
haya elegido debe quedar con la misma cantidad de campos que al principio. Los
encabezados deben ser los siguientes: Cliente, Dni, Domicilio, Barrio, Localidad, Edad. NO
EMPLEAR FUNCIONES que no se han visto en las clases o encuentros.
*/

create or alter function F_ObtenerEdad
(@fecha date)
returns int
as 
begin
declare 
	@dia int = datepart(day,@fecha),
	@mes int = datepart(MONTH,@fecha), 
	@respuesta int;
set @respuesta = case 
						when datepart(month,getdate()) -@mes =0  and DATEPART(day,getdate()) -@dia <=0 then datepart(year,getdate()) - DATEPART(year,@fecha)
						when datepart(month,getdate()) -@mes >0 then  datepart(year,getdate()) - DATEPART(year,@fecha) -1
						else datepart(year,getdate()) - DATEPART(year,@fecha)
					end
return @respuesta;
end

create or alter proc clientesPocosTelefonos
as
select dni_Cl as DNI,(nombre_Cl+' '+apellido_Cl)as Nombre,direccion_Cl as Direccion, (select descripcion_Barr from BARRIOS where codBarrio_Barr=codBarrio_Cl) as Barrio,(select descripcion_Loc from LOCALIDADES where codPostal_Loc=codLocalidad_Cl)as Localidad,(select descripcion_Gen from GENEROS where cod_Gen=codGen_Cl)as genero,dbo.F_ObtenerEdad(fechaNacimiento_Cl) as edad from clientes where dni_Cl in  (select top 3 dniCliente_TxC from TELEFONOSxCLIENTES group by dniCliente_TxC order by count(telefono_TxC)) and codGen_Cl=(select cod_Gen from GENEROS where descripcion_Gen = 'Femenino') ;

exec clientesPocosTelefonos

/*
### Consulta 3
- Mostrar un listado por medio de un procedimiento almacenado que informe el nombre
completo, tiempo trabajo en la empresa (el tiempo a considerar es hasta el momento en que
se realiza la consulta) y edad de aquellos vendedores que son los más jóvenes en la empresa.
Los encabezados que deben aparecer en la consulta son los siguientes: Vendedor/a, Años
Trabajados, Edad en la columna que corresponda. Si le resulta de utilidad añadir algún campo
o campos a la tabla que considere pertinente, para resolver este ejercicio, puede hacerlo.
Luego de ejecutar el procedimiento almacenado elimine los campos añadidos. NO
EMPLEAR funciones que no se han visto en las clases o encuentros.
*/
create proc vendedoresjovenes
as
select top 3  (nombre_Vd+' '+apellido_Vd) as "Vendedor/a",dbo.F_ObtenerEdad(fechaIngreso_Vd) as "Años trabajados",dbo.F_ObtenerEdad(fechaNacimiento_Vd) as Edad from VENDEDORES order by dbo.F_ObtenerEdad(fechaNacimiento_Vd);

exec vendedoresjovenes

/*
### Consulta 4
- Crear un procedimiento almacenado que informe el nombre completo, dni, dirección,
barrio, localidad, y el mayor número de compras realizadas entre todas las compras, de
aquellas mujeres que tienen una edad que es superior al promedio de las edades de los
hombres. Los hombres y mujeres que se toman en consideración son los clientes que están
registrados en la base de datos. Realice cambios a la tabla pertinente a modo de añadir algún
campo, si lo considera necesario. Luego de ejecutar el procedimiento almacenado elimine el
campo o campos añadidos a la tabla. Los encabezados en el resultado de la consulta, deben
ser los siguientes: Cliente, Dni, Dirección, Barrio, Localidad, Total de Compras Realizadas.
NO EMPLEAR funciones que no fueron dadas en los encuentros.
*/

create proc comprasmujeresxedad
as
select (nombre_Cl+' '+apellido_Cl) as Nombre,(direccion_Cl) as direccion,(select descripcion_Barr from BARRIOS where codBarrio_Barr=codBarrio_Cl) as barrio, (select descripcion_Loc from LOCALIDADES where codPostal_Loc=codLocalidad_Cl) as localidades ,(select top 1 sum(cantidadArt_DV) as "numero ventas" from DETALLE_VENTAS where idVenta_DV in (select id_Venta from VENTAS where dniCliente_Venta=dni_Cl) group by idVenta_DV order by [numero ventas] desc) as "Mayor Numero de ventas",dbo.F_ObtenerEdad(fechaNacimiento_Cl) as Edad from clientes where codGen_Cl = (select cod_Gen from GENEROS where descripcion_Gen= 'Femenino') and dbo.F_ObtenerEdad(fechaNacimiento_Cl) >(select avg(dbo.F_ObtenerEdad(fechaNacimiento_Cl)) from clientes where codGen_Cl=(select cod_Gen from GENEROS where descripcion_Gen= 'Masculino')) and dni_Cl in (select dniCliente_Venta from VENTAS);
exec comprasmujeresxedad