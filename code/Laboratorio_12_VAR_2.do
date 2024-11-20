clear all
cd "C:\Users\juanm\Documents\Respaldo\Clases\Macroeconometria\Asistencia\Laboratorio EC4301\Laboratorio 12 (VAR)"
use "LAB_VAR.dta", clear
tsset fecha
*********************************************************************************
*Del laboratorio pasado, habíamos seleccionado un VAR(1).

/*                            Test de Razón de verosimilitud                            */
*Prueba de razón de verosimilitud LR que rechaza la hipótesis nula de que los parámetros adicionales resultantes de sumar un rezago son conjuntamente cero.
describe // hay 39 observaciones y son datos trimestrales por lo tanto:
* 4 [(39/4)^(1/4)] = 7.06, entonces M = 8
*chi-cuadrada con k^2 = 9 grados de libertad para 5% es de 16.919
* Crear una tabla para guardar los resultados
gen lags = .
gen LR_stat = .
* Número máximo de rezagos a evaluar
local max_lags 8
forval m = 1/`max_lags' {
    * Modelo restringido (VAR con m rezagos)
    quietly varbasic INF DES TPM, lags(1/`m') nograph
    matrix Sigma_r = e(Sigma)
    * Modelo no restringido (VAR con m+1 rezagos)
    quietly varbasic INF DES TPM, lags(1/`=`m'+1') nograph
    matrix Sigma_u = e(Sigma)
    gen log_det_r = (ln(det(Sigma_r)))
    gen log_det_u = (ln(det(Sigma_u)))
    gen LR = 39*(log_det_r-log_det_u) // Número de observaciones
    replace lags = `m' in `m'
    replace LR_stat = LR in `m'
	drop log_det_r log_det_u LR
}
* Graficar LR vs. rezagos
twoway (line LR_stat lags, lcolor(blue) lwidth(medium)) ///
       (function y=16.919, range(lags) lcolor(red) lpattern(dash) lwidth(medium)), ///
       title("Likelihood Ratio vs. Rezagos") ///
       xlabel(1/8) ylabel(, angle(0)) ///
       legend(off)
*replace LR_stat = . in 8

/*                            Granger e impulso respuesta                            */
*Podemos calcular las funciones de impulso-respuesta unitarias.
varbasic INF DES TPM, lags(1/1) step(10) irf

*Podemos hacer pruebas de causalidad de Granger.
varbasic INF DES TPM, lags(1/1) nograph
vargranger // TPM causa a DES en el sentido de Granger
*Impulso respuesta ortogonales
var INF DES TPM, lags(1/1)
* (Stock y Watson 2001)
irf graph oirf // paradoja de los precios, incremento en la TPM aumenta la inflación en el corto plazo
*Autores señalan que posiblemente el Banco Central plantea una tasa de política monetaria sin observar señales de inflación futura

*Incluir precios de commodities puede proveer una aproximación sobre la inflación futura

//// Se muestra el efecto de un impulso de una desviación estándar en la ecuación de la tasa de interés. La inflación disminuye ligeramente después de ocho trimestres, pero la respuesta no es estadísticamente significativa en ningún horizonte. Los cambios suceden en puntos porcentuales

*Pero a veces queremos solo algunas impulso-respuesta a la vez.
irf create Modelo_1, set(Modelo) step(10) replace
irf graph oirf, impulse(TPM) response(INF DES TPM) yline(0,lcolor(black) lpattern(dash)) byopts(yrescale) xlabel(0(2)10)
*Un shock de una desviación estándar en la TPM tiene un efecto positivo gradual sobre el desempleo
/*Por si quisieran guardar el gráfico
graph export "IRF.pdf", replace
*/
*Un VAR no es ateórico. Cambiemos el orden:
irf create Modelo_2, order(TPM DES INF) step(10) replace
irf create Modelo_3, order(TPM INF DES) step(10) replace
irf create Modelo_4, order(INF TPM DES) step(10) replace
irf create Modelo_5, order(DES INF TPM) step(10) replace
irf create Modelo_6, order(DES TPM INF) step(10) replace

preserve
use Modelo.irf, clear
irf ograph (Modelo_1 TPM INF oirf) (Modelo_2 TPM INF oirf) (Modelo_3 TPM INF oirf) ///
(Modelo_4 TPM INF oirf) (Modelo_5 TPM INF oirf) (Modelo_6 TPM INF oirf), noci ///
yline(0,lcolor(black) lpattern(dash)) graphregion(color(white)) xlabel(0(2)10)

*Matriz de descomposición de Cholesky
* Desempleo y la tasa de política monetaria no tienen efectos contemporáneos en la inflación. Precios rígidos
* El desempleo responde con rezago a los cambios en la TPM. Inflación sí tiene efectos contemporáneos en el desempleo. Curva Phillips
* shocks en inflación y desempleo tienen efectos contemporáneos en la tasa de política monetaria. Banco Central tiene información de la economía para establecer la TPM

*Esto se debe a la descomposición de la varianza.
use Modelo.irf, clear
keep if irfname == "Modelo_5"
keep if response == "INF"
keep fevd step impulse
replace step = step - 1
drop if step == -1
reshape wide fevd, i(step) j(impulse) string
graph bar (asis) fevdTPM fevdINF fevdDES, over(step) stack graphregion(color(white)) ///
legend(order(1 "TPM" 2 "INF" 3 "DES") rows(1))
*graph export "E:\Laboratorio EC4301 IIS2023\Laboratorio 12 (VAR)\FEVDINFModelo5.pdf", replace
use Modelo.irf, clear
keep if irfname == "Modelo_6"
keep if response == "INF"
keep fevd step impulse
replace step = step - 1
drop if step == -1
reshape wide fevd, i(step) j(impulse) string
graph bar (asis) fevdTPM fevdINF fevdDES, over(step) stack graphregion(color(white)) ///
legend(order(1 "TPM" 2 "INF" 3 "DES") rows(1))
graph export "E:\Laboratorio EC4301 IIS2023\Laboratorio 12 (VAR)\FEVDINFModelo6.pdf", replace
capture erase Modelo.irf

*Adicionalmente
clear all
use "LAB_VAR.dta", clear
tsset fecha
matrix define A = (., 0, 0 \ ., ., 0 \ ., ., .)
svar INF DES TPM, lags (1/1) aeq(A)
irf create Modelo_S, set(SModel) step(10) replace
irf graph oirf, impulse(INF DES TPM) response(INF DES TPM)
vargranger


*Restricciones en corto plazo, largo plazo y restricciones de señales.