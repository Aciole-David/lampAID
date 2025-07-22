## // get glapd ref target and pretty highlighted primers ####

library(rentrez)    # NCBI entrez get sequence
library(dplyr)      # R's armyknife
library("ggplot2")  # Plotter BOSS
library(patchwork)  # Plots, ASSEMBLE!
library(stringr)    # String stuff

# inform genome id used as ref
id='JAAVTW010000004'
# get glapd conv csv files from containing folder
getname<-list.files(path = '..', pattern = paste0(id,".*csv"), recursive = T, include.dirs = T, full.names = T)
# read glapd conv csv
tab<-read.delim2(file = getname)


#inform set number
# setnum<-4
# setnum<-paste0('Set-',setnum)
# 
# tab$set

#for (setnum in tab$set) {
for (setnum in 'Set-9') {
  
  print(paste(id,'; ',setnum))
  
  tab2<-tab|>
    filter(set==setnum)
  
  # rentrez 
  #https://cran.r-project.org/web/packages/rentrez/index.html
  #https://www.ncbi.nlm.nih.gov/books/NBK25499/table/chapter4.T._valid_values_of__retmode_and/
  
  stt<-as.numeric(tab2$F3.stt)-5
  stp<-as.numeric(tab2$B3.stt+tab2$B3.len)+5
  aseq<-entrez_fetch(db="nuccore", id=id, rettype="fasta",
                     seq_start = stt+1, seq_stop = stp)
  
  sequence <- gsub(">", "", unlist(strsplit(aseq, "\n")))
  header <- sequence[1]
  sequence <- paste(sequence[-1], collapse="")
  
  bases<-data.frame(strsplit(sequence, split = ''))
  names(bases)<-'bases'
  flap<-tab2$F3.stt-1
  
  
  tab2<-tab2 |>
    select(!where(~str_detect(., '_')))|>
    mutate(across(
      contains('len')
      , ~as.numeric(.))
    )|>
    mutate(across(
      contains('stt')
      , ~as.numeric(.) - flap))
  
  #str(tab2)
  
  atitle<-paste0('Start:',stt, ' <<< ',header,' >>> End:',stp)
  
  atitleposition<-nchar(sequence)/2
  
  tagplaces<-(tab2[,grep('stt', names(tab2))])
  names(tagplaces)<-gsub(x = names(tagplaces),pattern = '.stt',replacement = '')
  tagseqs<-as.vector(tab2[,grep('seq', names(tab2))])
  tagcenter<-(tab2[,grep('stt', names(tab2))])+(tab2[,grep('len', names(tab2))]/2)
  
  tagcols<-factor(x = names(tagplaces), levels = names(tagplaces))
  
  
  apdf<-paste0(id,'-',setnum,'_prettyseq.pdf')
  apage<-paste0(id,'-',setnum,'_prettyseq')
  
  try(dev.off())
  
  pdf(file = apdf, width = nchar(sequence)/5.15, height = 20,family = 'mono', title = apage)
  
  ggplot() +
    
    # TARGET
    geom_text(aes(x = 1:nrow(bases), label = bases$bases, y =.17), size = 7, family = 'mono')+
    
    # PRIMERS SEQUENCES
    geom_label(fill='grey',hjust = 0, vjust=0,label.size = 0,label.r = unit(0,'mm'),
               label.padding = unit(-4,'mm'),family = 'mono',show.legend = F,alpha = 0,
               aes(x = as.numeric(tagplaces)+4.45,y = .2,
                   label = as.list(paste('',tagseqs,'')),col=tagcols), cex = 7)+
    # PREIMERS NAMES
    geom_label(aes(label=names(tagplaces),fill=tagcols,
                   x=as.numeric(tagcenter)+4, y = .3),fontface='bold',family='mono',
               show.legend = F, size=7)+
    # TARGET HEADER
    annotate(geom = 'text', x = atitleposition, y = .4, fontface='bold',label=atitle, size =8,
             family='mono')+
    
    
    scale_y_continuous(name = '', expand = c(0,0), limits = c(0,.5))+
    scale_x_continuous(n.breaks = nchar(sequence), name = '', breaks = NULL)+
    scale_fill_discrete()+
    
    theme_minimal()+
    theme(plot.margin = unit(rep(0,4), 'cm'))->aa
  


#gc()

## //TM CALC ####

# Get TM from primers

#install.packages('TmCalculator')
library(tibble)
library(reshape2)
library(TmCalculator)

# concentration parameters
# 1X Buffer Components
# 20 mM Tris-HCl
# 10 mM (NH4)2SO4
# 50 mM KCl
# 2 mM MgSO4
# 0.1% Tween® 20
# pH 8.8@25°C


tmfun<-function(inputseq){
  Tm_GC(inputseq,
      ambiguous=F,
      #variant="Primer3Plus", #Empirical constants coefficient
      Tris=20,
      K=50,
      Mg = 2,
      mismatch=F, outlist = F)}

library(stringr)
library(dplyr)

library('spgs')

tmtab<-as.data.frame((tagseqs))
tmtab<-as.data.frame(t(tmtab))
names(tmtab)<-'seqs'
tmtab

tmtab$sense<-paste0('.....',tmtab$seqs)
tmtab$sense<-str_extract(sequence, tmtab$sense)

tmtab$asense<-toupper(reverseComplement(tmtab$seqs))
tmtab$asense<-paste0(tmtab$asense,'.....')


tmtab$sense<-str_extract(sequence, tmtab$sense)
tmtab$asense<-str_extract(sequence, tmtab$asense)


tmtab<-tmtab|>
  mutate('add_5'=ifelse(
    is.na(sense), #if is NA
    str_sub(asense,end = -1), # keep 
    str_sub(sense,start = 1)) # else, sub
    )|>
  mutate('add_4'=ifelse(
    is.na(sense), #if is NA
    str_sub(asense,end = -2), # keep 
    str_sub(sense,start = 2)) # else, sub
    )|>
  mutate('add_3'=ifelse(
    is.na(sense), #if is NA
    str_sub(asense,end = -3), # keep 
    str_sub(sense,start = 3)) # else, sub
    )|>
  mutate('add_2'=ifelse(
    is.na(sense), #if is NA
    str_sub(asense,end = -4), # keep 
    str_sub(sense,start = 4)) # else, sub
    )|>
  mutate('add_1'=ifelse(
    is.na(sense), #if is NA
    str_sub(asense,end = -5), # keep 
    str_sub(sense,start = 5)) # else, sub
    )|>
  mutate('add_0'=ifelse(
    is.na(sense), #if is NA
    str_sub(asense,end = -6), # keep 
    str_sub(sense,start = 6)) # else, sub
    )|>
  rownames_to_column(var = 'names')

tmtab<-tmtab|>
  mutate('tmadd_5'=round(unlist(lapply(tmtab$add_5, tmfun)), digits = 2))|>
  mutate('tmadd_4'=round(unlist(lapply(tmtab$add_4, tmfun)), digits = 2))|>
  mutate('tmadd_3'=round(unlist(lapply(tmtab$add_3, tmfun)), digits = 2))|>
  mutate('tmadd_2'=round(unlist(lapply(tmtab$add_2, tmfun)), digits = 2))|>
  mutate('tmadd_1'=round(unlist(lapply(tmtab$add_1, tmfun)), digits = 2))|>
  mutate('tmadd_0'=round(unlist(lapply(tmtab$add_0, tmfun)), digits = 2))



library(tidyr)

tmtab[,c(1,11:16)] %>%
  gather(added, Tm, -names)|>
  ggplot()+
  geom_text(aes(x=added, y=Tm, label = Tm, color=Tm), size=10)+
  facet_wrap(~names, scales = 'free')+
  scale_color_gradient(low = 'blue', high = 'red')+
  theme(text = element_text(size=30))-> bb


  final<-(aa / bb)+plot_layout(heights = c(1,4))
  print(final)
  dev.off()
  
}

for (totalrows in 1:nrow(tm5l)) {

for (starts in 1:6) {
#for (starts in 3) {
  aseq<-stringr::str_sub(string = tm5l$seq[totalrows], start = starts)
  aseq
  tm<-round(tmfun(inputseq = aseq), digits = 2)
  tm
  #print(paste0(seq,'\t',tm))
  tmtmp[starts,]$name<-tm5l$name[totalrows]
  tmtmp[starts,]$seq<-aseq
  tmtmp[starts,]$tm<-tm
  tmtmp[starts,]$add<-(6-starts)
}
rownames(tmtmp)<-1:nrow(tmtmp)
tmfinal<-rbind(tmfinal,tmtmp)
}

tmfinal<-tmfinal[-1,]
rownames(tmfinal)<-1:nrow(tmfinal)


lll

lll$tm<-round(tmfun(inputseq = 'ACAGTGGAACTCCATGTGTAGCGG'), digits = 2)
lll

tmtable$tm<-lapply(tmtable$seq,tmfun)

#plot tm
tmtable<-tmtable[!duplicated(tmtable), ]
tmtable$tm<-as.numeric(tmtable$tm)

unique(tmtable$name)

factor(tmtable$name,
                       levels=unique(tmtable$name))

tmtable$nameorder = factor(tmtable$name,
                       levels=unique(tmtable$name))

tmtable$tmround<-round(tmtable$tm, digits = 2)


tmtable$tmoverlap<-ifelse(
  tmtable$overlap=="",tmtable$tmround,
  paste0("*",tmtable$tmround,"\n",tmtable$overlap)
)

tmtable$overlap<-ifelse(
  tmtable$overlap=="","",
  paste0(tmtable$name," ",tmtable$added," ",tmtable$overlap)
)


library(ggplot2)


png(filename = 'test-plot.pdf', width = 1800, height = 800, res = 100)
ggplot(data = tmfinal)+
  theme_bw()+
  #geom_point(cex=3,mapping = aes(y=tm, x = Added, color=tm))+
  geom_text(cex=3,mapping = aes(y=tm, x = add, color=tm, label=tm))+
  scale_color_gradient(low = 'black', high = 'red', name = 'Tm [ \u00B0 C ]')+
  scale_x_continuous(breaks = -5:5, name = 'Bases added')+
  scale_y_continuous(n.breaks = 6, name = 'Calculated Tm [ \u00B0 C ]',expand = expansion(mult = 0, add = 1.5))+
    facet_wrap(~name, scales = 'fixed', ncol = 2)+
  labs(title = 'Lacto set L16S1 primer Tm predict', subtitle = '* overlap F1c-B1c; B2-B3')
dev.off()
