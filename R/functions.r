
#' Extract images from DynamicFire NetLogo Model saved view 
#' 
#' The images were saved with the NetLogo extension CSV each 30 steps (ticks) after 7200 steps 
#'
#' @param fname 
#' @param plot 
#'
#' @return
#' @export
#'
#' @examples
extract_patch_distr_nl <- function(fname,plot=FALSE){
  #
  # Extract parameters encoded in names
  #
  ss <- data.frame(str_split(tools::file_path_sans_ext(fname),"_",simplify=TRUE),stringsAsFactors = FALSE) %>% mutate_at(2:7,as.numeric)
  plan(multisession)
  p_df <- future_lapply( 2:length(fname), function(h){
    
  png <- read_csv(paste0("Data/",fname[h-1]),col_names = c("i","j","value"), col_types = cols()) %>% filter(value!=55 & value!=0) %>% mutate(value= value>0)
  png1 <- read_csv(paste0("Data/",fname[h]),col_names = c("i","j","value"),  col_types = cols()) %>% filter(value!=55 & value!=0) %>% mutate(value= value>0)
  dif <- anti_join(png1,png, by=c("i","j"))
  #ggplot(dif, aes(y=i,x=j,fill=value)) +geom_raster() + theme_void()
  #ggplot(png, aes(y=i,x=j,fill=value)) +geom_raster() + theme_void() 
  #ggplot(png1, aes(y=i,x=j,fill=value)) +geom_raster() + theme_void()
  if( nrow(dif)>0) {
    sm <- sparseMatrix(i=dif$i+1,j=dif$j+1,x=dif$value)
    pl <- patchdistr_sews(as.matrix(sm))
    if(plot) print(plot_distr(pl,best_only = FALSE) + ggtitle(paste("Days",ss[h,5])))
          
    pl <- tibble::remove_rownames(data.frame(pl))
    patch_distr <- patchsizes(as.matrix(sm))
    pl <- pl %>% mutate(max_patch = max(patch_distr),size=as.numeric(ss[h,7])*as.numeric(ss[h,8]),tot_patch=sum(patch_distr),days = ss[h,6], 
                        initial_forest_density= ss[h,2], fire_probability = ss[h,3], forest_dispersal_distance = ss[h, 4],
                        forest_growth= ss[h,5]
                        )
  }
  }, future.seed = TRUE)
  plan(sequential)
  patch <- bind_rows(p_df)
  return(patch)
}

#' Evaluate patch distribution in a raster brick 
#'
#' @param br raster with distribution data >0 is TRUE   
#' @param returnEWS if TRUE returns the early warnings, FALSE returns the patch distribution   
#'
#' @return a data frame with results
#' @export
#'
#' @examples
evaluate_patch_distr <- function(br,returnEWS=TRUE){
  if( class(br)!="RasterLayer")
    stop("Paramter br has to be a RasteLayer")
  ## Convert to TRUE/FALSE matrix
  #
  brTF <- as.matrix(br)
  brTF <- brTF>0
  
  # Extract Date from name of the band
  #
  brName <- str_sub( str_replace_all(names(br), "\\.", "-"), 2)
  
  if( returnEWS ){
    patch_distr <- patchdistr_sews(brTF)
    
    patch_df <- tibble::remove_rownames(data.frame(patch_distr)) %>% mutate(date=brName) 
  } else {
    patch_distr <- patchsizes(brTF)
    patch_df <- tibble(size=patch_distr) %>% mutate(date=brName) 
    
  }
  return(patch_df)
}


convert_to_sparse <- function(fire_bricks,region_name){
  
  future::plan(multiprocess)
  on.exit(future::plan(sequential))
  
  require(Matrix)
  p_df <- lapply( seq_along(fire_bricks), function(ii){
    
    br <- brick(paste0("Data/",fire_bricks[ii]))
    df <- future_lapply(seq_len(nbands(br)), function(x){
      brName <- stringr::str_sub( stringr::str_replace_all(names(br[[x]]), "\\.", "-"), 2)
      mm <- as.matrix(br[[x]]>0)
      message(paste(x,"-", brName ,"Suma de fuegos", sum(mm)))
      sm <- as(mm,"sparseMatrix")
      
      summ <- as_tibble(summary(sm)) 
      names(summ) <- c("i","j","data")
      summ <- summ %>% mutate(t=x,date=brName) %>% dplyr::select(t,i,j,data,date)
    })
    #yy <- str_sub(names(br)[1],2,5)
    df <- do.call(rbind,df) %>% mutate(region=region_name)
  })
  p_df <- do.call(rbind,p_df)
  
}