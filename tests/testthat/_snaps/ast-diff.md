# expect_pd_ast_equal reports a side-by-side tree diff on mismatch

    Code
      cat(msg)
    Output
      pd ast mismatch (actual: 9 lines, expected: 12 lines):
      < `a`                          > `b`                        
      @@ 5,5 @@                      @@ 5,8 @@                    
         5 │   ├─str "plain"            5 │   ├─str "plain"       
         6 │   ├─space                  6 │   ├─space             
      <  7 │   ├─str "text"          >  7 │   ├─emph              
      ~                              >  8 │   │ └─str "emphasised"
      ~                              >  9 │   ├─space             
      ~                              > 10 │   ├─str "text"        
      <  8 │   ├─space               > 11 │   ├─space             
      <  9 │   └─str "here."         > 12 │   └─str "here."       

# expect_ts_ast_equal reports a side-by-side tree diff on mismatch

    Code
      cat(msg)
    Output
      ts ast mismatch (actual: 12 lines, expected: 16 lines):
      < `a`                                     > `b`                                   
      @@ 7,6 @@                                 @@ 7,10 @@                              
         7 │     └─pandoc_paragraph                7 │     └─pandoc_paragraph           
         8 │       ├─pandoc_str "plain"            8 │       ├─pandoc_str "plain"       
      <  9 │       ├─pandoc_space " "           >  9 │       ├─pandoc_emph              
      ~                                         > 10 │       │ ├─emphasis_delimiter " *"
      ~                                         > 11 │       │ ├─pandoc_str "emphasised"
      ~                                         > 12 │       │ └─emphasis_delimiter "*" 
      ~                                         > 13 │       ├─pandoc_space " "         
      < 10 │       ├─pandoc_str "text"          > 14 │       ├─pandoc_str "text"        
      < 11 │       ├─pandoc_space " "           > 15 │       ├─pandoc_space " "         
      < 12 │       └─pandoc_str "here."         > 16 │       └─pandoc_str "here."       

# expect_pd_ast_equal truncates very large diffs

    Code
      cat(msg)
    Output
      pd ast mismatch (actual: 163 lines, expected: 163 lines):
      < `a`                     > `b`                   
      @@ 3,161 @@               @@ 3,161 @@             
          3 │ │ └─str "H"           3 │ │ └─str "H"     
          4 │ └─paragraph           4 │ └─paragraph     
      <   5 │   ├─str "alpha."  >   5 │   ├─str "beta." 
          6 │   ├─space             6 │   ├─space       
      <   7 │   ├─str "alpha."  >   7 │   ├─str "beta." 
          8 │   ├─space             8 │   ├─space       
      <   9 │   ├─str "alpha."  >   9 │   ├─str "beta." 
         10 │   ├─space            10 │   ├─space       
      <  11 │   ├─str "alpha."  >  11 │   ├─str "beta." 
         12 │   ├─space            12 │   ├─space       
      <  13 │   ├─str "alpha."  >  13 │   ├─str "beta." 
         14 │   ├─space            14 │   ├─space       
      <  15 │   ├─str "alpha."  >  15 │   ├─str "beta." 
         16 │   ├─space            16 │   ├─space       
      <  17 │   ├─str "alpha."  >  17 │   ├─str "beta." 
         18 │   ├─space            18 │   ├─space       
      <  19 │   ├─str "alpha."  >  19 │   ├─str "beta." 
         20 │   ├─space            20 │   ├─space       
      <  21 │   ├─str "alpha."  >  21 │   ├─str "beta." 
         22 │   ├─space            22 │   ├─space       
      <  23 │   ├─str "alpha."  >  23 │   ├─str "beta." 
         24 │   ├─space            24 │   ├─space       
      <  25 │   ├─str "alpha."  >  25 │   ├─str "beta." 
         26 │   ├─space            26 │   ├─space       
      <  27 │   ├─str "alpha."  >  27 │   ├─str "beta." 
         28 │   ├─space            28 │   ├─space       
      <  29 │   ├─str "alpha."  >  29 │   ├─str "beta." 
         30 │   ├─space            30 │   ├─space       
      ... omitted 133/162 lines

