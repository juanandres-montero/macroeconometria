********************************************************************************
/*Simular un ARCH(1)
y_{t} = 10 + \epsilon_{t}
\epsilon_{t} = u_{t}\sqrt{0.4 + 0.5(\epsilon^2_{t-1})} 
*/
/*Creamos 1000 observaciones; fijamos una semilla; y establecemos el índice de 
serie de tiempo*/
clear all
set obs 1000
set seed 12345
gen time= _n
tsset time
*Creamos u_{t}
gen u = rnormal(0,1)
*Generamos los errores
gen epsilon = 0
replace epsilon = u*sqrt(0.4 + 0.5*(L.epsilon*L.epsilon)) if time > 1
*Y ya podemos crear nuestra serie de tiempo
gen x =10 + epsilon
tsline x
*Y la estimamos
arch x, arch(1)
********************************************************************************

********************************************************************************
/*Simular un GARCH(1,1)
y_{t} = 10 + \epsilon_{t}
\epsilon_{t} = (u_{t})*\sigma_{t}
\sigma^2_{t} =  0.2 + 0.4(\epsilon^2_{t-1}) + 0.6(\sigma^2_{t-1})
*/
/*Creamos 1000 observaciones; fijamos una semilla; y establecemos el índice de 
serie de tiempo*/
clear all
set obs 1000
set seed 12345
gen time= _n
tsset time
*Creamos u_{t}
gen u = rnormal(0,1)
*Generamos los errores y además debemos crear la varianza condicional
gen epsilon = 0
gen sigma2 = 1
forvalues i=2/1000{
	replace sigma2 = 0.2 + 0.4*(L.epsilon*L.epsilon) + 0.6*(L.sigma2) if time == `i'
	replace epsilon = u*sqrt(sigma2) if time == `i'
}
*Y ya podemos crear nuestra serie de tiempo
gen w = 10 + epsilon
tsline w
*Y la estimamos.
arch w, arch(1) garch(1)
********************************************************************************

********************************************************************************
/*Estimar un GARCH para la tasa de cambio porcentual del tipo de cambio de compra 
colón-dólar.*/
clear all
cd "C:/Users/User/Documents/Downloads"
import excel "tipo_cambio.xlsx", sheet("Hoja1") firstrow
*Declaramos nuestra variable temporal.
tsset FECHA
*Calculamos la tasa de cambio porcentual de COMPRA.
generate tasa_cambio = (D.COMPRA/L.COMPRA)*100
*El supuesto de varianza constante parece cuestionable gráficamente:
tsline tasa_cambio
/*Para evaluarlo con más rigor estudiaremos los errores del mejor modelo según
la metodología Box-Jenkins:*/
arima tasa_cambio, arima(4,0,4)
predict error, resid
*En concreto, queremos el autocorrelograma de los errores al cuadrado
generate error_cuadrado = error*error
ac error_cuadrado
*Y corroboramos formalmente con una prueba de Ljung-Box:
wntestq error_cuadrado
*Efectivamente, hay evidencia de que una especificación GARCH sería apropiada.
/*Finalmente, haremos un test de McLeod-Li corriendo una regresión por MCO de 
los errores al cuadrado con respecto a sus primeros 15 rezagos:*/
regress error_cuadrado L(1/15).error_cuadrado
*Usaremos un modelo ARIMA con errores GARCH
arch tasa_cambio, arch(1) ar(4) ma(4)
*cuidado
arch tasa_cambio, arch(1) ar(1/4) ma(1/4)
*Valor del AIC
estat ic
*Encontrar mejor 
forvalues p=0/2{
forvalues q=1/2{
	if `p'==0{
		quietly arch tasa_cambio, arch(1/`q') ar(4) ma(4)
	}
	else {
		quietly arch tasa_cambio, arch(1/`q') garch(1/`p') ar(4) ma(4)
	}
	quietly estat ic
	matrix temp = r(S)
	display "p = " `p' " q = " `q' " AIC = " temp[1,5] " BIC = " temp[1,6]
}
}
********************************************************************************
*Mejor GARCH(1,2)