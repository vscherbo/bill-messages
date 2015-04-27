/^SELECT/,/^WHERE/ { s_expr[i++]=$0; next}
/^$/ {
      #for (j=0; j<=i; j++) print j"->"s_expr[j]
      for (j=0; j<=i; j++) if (s_expr[j] != "") {max_j=j*10; valid_s[max_j]=s_expr[j] }
      
      #for (n=0; n<=max_j; n++) print n"-->"valid_s[n]

      #valid_s[0]=s_expr[0]    # 1st SELECT
      valid_s[max_j-2]=s_expr[1]  # 2-nd FROM
      valid_s[max_j-1]=s_expr[2]  # 3-rd table_name
      delete valid_s[10]
      delete valid_s[20]
      #valid_s[j]=s_expr[j] #last line WHERE
      for (k=0;  k<=max_j; k++) if (valid_s[k] != "") print valid_s[k]
      print
  
      delete s_expr
      delete valid_s 
      i=0; j=0; k=0
}
