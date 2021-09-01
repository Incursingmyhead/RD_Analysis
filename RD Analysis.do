** graph raw data 

scatter ccp_p pedyr , msize(mid) xline(93) ytitle("入党率")xtitle("班级排名")

scatter lnexpminc cutoff_pct, msize(mid) xline(93) ytitle("初职能接受的最低收入") xtitle("分数线分数比")

scatter lninc cutoff_pct, msize(mid) xline(96) ytitle("初职收入") xtitle("分数线分数比")

scatter classrank cutoff_pct, msize(mid) xline(93) ytitle("班级排名") xtitle("分数线分数比")

scatter ccp cutoff_pct, msize(mid) xline(96) ytitle("是否入党") xtitle("分数线分数比")

scatter outcome cutoff_pct, msize(mid) xline(96) ytitle("大学毕业出路") xtitle("分数线分数比")

scatter pedyr cutoff_pct, msize(mid) xline(96) ytitle("父母受教育程度") xtitle("分数线分数比")


binscatter  classrank cutoff_pct if cutoff_pct>=86 & cutoff_pct<=100, n(100) rd(93) linetype(qfit)

cmogram classrank cutoff_pct if cutoff_pct>=86 & cutoff_pct<=100, scatter cut(93) lineat(0) lfit ci(74) histopts(bin(50))

binscatter outcome cutoff_pct if cutoff_pct>=97 & cutoff_pct<=100, n(100) rd(99) linetype(qfit)

binscatter lninc cutoff_pct if cutoff_pct>=86 & cutoff_pct<=100, n(100) rd(93) linetype(qfit)

capture drop X2 Y2 r2 fhat2 se_fhat2
DCdensity cutoff_pct if cutoff_pct>=85 & cutoff_pct<=95, breakpoint(90) gen(X2 Y2 r2 fhat2 se_fhat2)
