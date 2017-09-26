<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:my="local functions">

  <!-- Variables from XML teiHeader -->
  <xsl:param name="apploc"><xsl:value-of select="/TEI/teiHeader/encodingDesc/variantEncoding/@location"/></xsl:param>
  <xsl:param name="notesloc"><xsl:value-of select="/TEI/teiHeader/encodingDesc/variantEncoding/@location"/></xsl:param>
  <xsl:variable name="title"><xsl:value-of select="/TEI/teiHeader/fileDesc/titleStmt/title"/></xsl:variable>
  <xsl:variable name="author"><xsl:value-of select="/TEI/teiHeader/fileDesc/titleStmt/author"/></xsl:variable>
  <xsl:variable name="editor"><xsl:value-of select="/TEI/teiHeader/fileDesc/titleStmt/editor"/></xsl:variable>

  <!-- get versioning numbers -->
  <xsl:param name="sourceversion"><xsl:value-of select="/TEI/teiHeader/fileDesc/editionStmt/edition/@n"/></xsl:param>

  <!-- this xsltconvnumber should be the same as the git tag, and for any commit past the tag should be the tag name plus '-dev' -->
  <xsl:param name="conversionversion">dev</xsl:param>

  <!-- combined version number should have mirror syntax of an equation x+y source+conversion -->
  <xsl:variable name="combinedversionnumber"><xsl:value-of select="$sourceversion"/>+<xsl:value-of select="$conversionversion"/></xsl:variable>
  <!-- end versioning numbers -->

  <!-- BEGIN: Document configuration -->
  <!-- Variables -->
  <xsl:variable name="starts_on" select="/TEI/text/front/div/pb"/>

  <!-- Command line parameters -->
  <xsl:param name="name-list-file">../../lists/prosopography.xml</xsl:param>
  <xsl:param name="work-list-file">../../lists/workscited.xml</xsl:param>
  <xsl:param name="app-entry-separator">;</xsl:param>
  <xsl:param name="font-size">12</xsl:param>
  <xsl:param name="ignore-spelling-variants">no</xsl:param>
  <xsl:param name="positive-apparatus">no</xsl:param>
  <xsl:param name="create-critical-apparatus">yes</xsl:param>
  <xsl:param name="apparatus-numbering">no</xsl:param>
  <xsl:param name="parallel-translation">no</xsl:param>
  <xsl:param name="app-fontium-quote">no</xsl:param>
  <xsl:param name="include-app-notes">no</xsl:param>
  <xsl:param name="app-notes-in-separate-apparatus">yes</xsl:param>
  <xsl:param name="standalone-document">yes</xsl:param>
  <xsl:param name="create-structure-numbers">yes</xsl:param>
  <xsl:param name="title-heading-level">section*</xsl:param>

  <!--
      Boolean check lists.
      To make command line parameters more robust, we check whether the value
      passed is one of the possible true or false values defined in these two
      lists with the test "parameter-name = boolean-true/*" (or boolean-false)
      if we test for false value.
  -->
  <xsl:variable name="boolean-true">
    <n>yes</n>
    <n>true</n>
    <n>1</n>
  </xsl:variable>

  <xsl:variable name="boolean-false">
    <n>no</n>
    <n>true</n>
    <n>0</n>
  </xsl:variable>

  <xsl:function name="my:istrue">
    <xsl:param name="parameter-name"/>
    <xsl:if test="lower-case($parameter-name) = $boolean-true/*">
      <xsl:value-of select="true()"/>
    </xsl:if>
  </xsl:function>

  <xsl:function name="my:isfalse">
    <xsl:param name="parameter-name"/>
    <xsl:if test="lower-case($parameter-name) = $boolean-false/*">
      <xsl:value-of select="true()"/>
    </xsl:if>
  </xsl:function>

  <xsl:function name="my:format-lemma">
    <xsl:param name="text"/>
    <xsl:value-of select="normalize-space(lower-case($text))"/>
  </xsl:function>


  <!-- END: Document configuration -->

  <xsl:output method="text" indent="no"/>
  <xsl:strip-space elements="div"/>
  <xsl:template match="text()">
    <xsl:value-of select="replace(., '\s+', ' ')"/>
  </xsl:template>

  <xsl:variable name="text_language">
    <xsl:choose>
      <xsl:when test="//text[@xml:lang='la']">latin</xsl:when>
      <xsl:otherwise>english</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:template match="body">
    <xsl:choose>
      <xsl:when test="my:istrue($parallel-translation)">
        \begin{pages}
        \begin{Leftside}
        <xsl:call-template name="documentDiv">
          <xsl:with-param name="content" select="//body/div" />
          <xsl:with-param name="inParallelText" select="false()"/>
        </xsl:call-template>
        \end{Leftside}

        \begin{Rightside}
        <xsl:call-template name="documentDiv">
          <xsl:with-param name="content" select="document($translationFile)//body/div" />
          <xsl:with-param name="inParallelText" select="true()"/>
        </xsl:call-template>
        \end{Rightside}
        \end{pages}
        \Pages
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="//body/div"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- Create endnotes (`<note>`s within `<app>`). -->
    <xsl:if test="my:istrue($include-app-notes) and
                  my:istrue($app-notes-in-separate-apparatus)">
      <xsl:text>
        \clearpage
        \section*{Critical apparatus notes}
        Format: \verb+n[-nn].x[-y]+ where \verb+n+ and \verb+nn+ = pagenumbers and verb+x+ and \verb+y+ =
        linenumbers. Content of brackets is optional.

        \doendnotes{A}
      </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- TRANSLATION STUFF -->
  <xsl:template name="documentDiv">
    <xsl:param name="content"/>
    <xsl:param name="inParallelText"/>
    <xsl:apply-templates select="$content">
      <xsl:with-param name="inParallelText" select="$inParallelText"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:variable name="translationFile">
    <xsl:variable name="absolute-path" select="base-uri(.)"/>
    <xsl:variable name="base-filename" select="tokenize($absolute-path, '/')[last()]"/>
    <xsl:variable name="parent" select="string-join(tokenize($absolute-path,'/')[position() &lt; last()], '/')" />
    <xsl:variable name="translation-file" select="concat($parent, '/translation-', $base-filename)"/>
    <xsl:choose>
      <xsl:when test="$translation-file">
        <xsl:value-of select="$translation-file"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          The translation file $translation-file cannot be found!
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:template match="front/div">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- PREAMBLE -->
  <xsl:template match="/">
    <xsl:if test="my:istrue($standalone-document)">
      %this tex file was auto produced from TEI by lbp_print on <xsl:value-of select="current-dateTime()"/> 
      \documentclass[a4paper, <xsl:value-of select="$font-size"/>pt]{book}

      % imakeidx must be loaded beore eledmac
      \usepackage{imakeidx}
      \usepackage{libertine}
      \usepackage{csquotes}

      \usepackage{geometry}
      \geometry{left=4cm, right=4cm, top=3cm, bottom=3cm}

      \usepackage{fancyhdr}
      % fancyheading settings
      \pagestyle{fancy}

      % latin language
      \usepackage{polyglossia}
      \setmainlanguage{english}
      \setotherlanguage{latin}

      % a critical mark
      \usepackage{amssymb}

      % git package
      \usepackage{gitinfo2}


      % title settings
      \usepackage{titlesec}
      \titleformat{\chapter}{\normalfont\large\scshape}{\thechapter}{50pt}{}
      \titleformat{\section}{\normalfont\scshape}{\thesection}{1em}{}
      \titleformat{\subsection}[block]{\centering\normalfont\itshape}{\thesubsection}{}{}
      \titlespacing*{\subsection}{20pt}{3.25ex plus 1ex minus .2 ex}{1.5ex plus .2ex}[20pt]

      % reledmac settings
      \usepackage[final]{reledmac}

      \Xinplaceoflemmaseparator{0pt} % Don't add space after nolemma notes.
      \Xlemmadisablefontselection[A] % In fontium lemmata, don't copy font formatting.
      \Xarrangement{paragraph}
      \linenummargin{outer}
      \sidenotemargin{inner}
      \lineation{page}

      \Xendbeforepagenumber{}
      \Xendafterpagenumber{.}
      \Xendlineprefixsingle{}
      \Xendlineprefixmore{}

      \Xnumberonlyfirstinline[]
      \Xnumberonlyfirstintwolines[]
      \Xbeforenotes{\baselineskip}

      % This should prevent overfull vboxes
      \AtBeginDocument{\Xmaxhnotes{0.5\textheight}}
      \AtBeginDocument{\maxhnotesX{0.5\textheight}}

      \Xprenotes{\baselineskip}

      \let\Afootnoterule=\relax
      \let\Bfootnoterule=\relax

      % other settings
      \linespread{1.1}

      % Critical edition sections
      \usepackage{titlesec}
      \titleclass{\extrasection}{straight}[\section]
      \titleclass{\extrasubsection}{straight}[\subsection]
      \titleformat{\extrasection}[display]
      {\scshape\Large\fillast}
      {}
      {1ex minus .1ex}
      {}
      \titleformat{\extrasubsection}[display]
      {\itshape\large\fillast}
      {}
      {1ex minus .1ex}
      {}
      \titlespacing{\extrasection}{20pt}{*4}{*2}[20pt]
      \titlespacing*{\extrasubsection}{20pt}{*4}{*2}[20pt]
      \newcounter{extrasection}
      \newcounter{extrasubsection}

      <xsl:if test="my:istrue($parallel-translation)">
        <xsl:text>
          % reledpar setup
          \usepackage{reledpar}
        </xsl:text>
      </xsl:if>

      % custom macros
      \newcommand{\name}[1]{#1}
      \newcommand{\lemmaQuote}[1]{\textsc{#1}}
      \newcommand{\worktitle}[1]{\textit{#1}}
      \newcommand{\supplied}[1]{⟨#1⟩} <!-- Previously I used ⟨#1⟩ -->
      \newcommand{\suppliedInVacuo}[1]{$\ulcorner$#1$\urcorner$} <!-- Text added where witnes(es) preserve a space -->
      \newcommand{\secluded}[1]{{[}#1{]}}
      \newcommand{\metatext}[1]{&lt;#1&gt;}
      \newcommand{\hand}[1]{\textsuperscript{#1}}
      \newcommand{\del}[1]{[#1 del. ms]}
      \newcommand{\no}[1]{\emph{#1}\quad}
      \newcommand{\corruption}[1]{\textdagger#1\textdagger}
      \newcommand{\lacuna}{\supplied{\textasteriskcentered\textasteriskcentered\textasteriskcentered}}

      <xsl:if test="/TEI/teiHeader/revisionDesc/@status = 'draft'">
        \usepackage{draftwatermark}
        \SetWatermarkText{DRAFT}
        \SetWatermarkFontSize{3.5cm}
        \SetWatermarkColor[gray]{0.9}
      </xsl:if>


      \begin{document}
      \fancyhead{}
      \fancyfoot[C]{\thepage}
      \fancyhead[L]{<xsl:value-of select="$author"/>: <xsl:value-of select="$title"/>}
      \setlength{\headheight}{15pt}

    </xsl:if>


    \<xsl:value-of select="$title-heading-level"/>{<xsl:value-of select="$author"/>: <xsl:value-of select="$title"/>}

    <xsl:apply-templates select="//body"/>

    <xsl:if test="my:istrue($standalone-document)">
      \end{document}
    </xsl:if>
  </xsl:template>



  <!-- BLOCK ELEMENTS -->
  <xsl:template match="head">
    <xsl:if test="not(following-sibling::p)">
      \extrasubsection*{<xsl:apply-templates/>}
    </xsl:if>
  </xsl:template>

  <xsl:template name="paragraphs" match="p">
    <xsl:param name="inParallelText"/>
    <xsl:variable name="pn"><xsl:number level="any" from="tei:text"/></xsl:variable>
    <xsl:variable name="p_count" select="count(//body/div/descendant::p)"/>
    <xsl:variable name="p_position">
      <xsl:number from="/TEI/text/body/div" level="any"/>
    </xsl:variable>
    <xsl:if test="$pn='1'">
      <xsl:text>&#xa;&#xa;\begin{</xsl:text>
      <xsl:value-of select="$text_language"/>
      <xsl:text>}</xsl:text>
      <xsl:text>&#xa;\beginnumbering
      </xsl:text>
    </xsl:if>
    <xsl:text>&#xa;\pstart</xsl:text>
    <xsl:if test="preceding-sibling::*[1][self::head] or
                  ((parent::div[1]/translate(@ana, '#', '') = $structure-types/*) and (position() = 1))">
      <xsl:text>[</xsl:text>
      <xsl:if test="preceding-sibling::head">
        <xsl:text>\extrasubsection{</xsl:text>
        <xsl:apply-templates select="preceding-sibling::head/node()"/>
        <xsl:text>}</xsl:text>
      </xsl:if>
      <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:call-template name="createLabelFromId">
      <xsl:with-param name="labelType">start</xsl:with-param>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
    <xsl:if test="$pn='1'">
      <xsl:call-template name="createPageColumnBreak">
        <xsl:with-param name="withIndicator" select="false()"/>
        <xsl:with-param name="context" select="$starts_on"/>
        <xsl:with-param name="inParallelText" select="$inParallelText"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="my:istrue($create-structure-numbers)">
      <xsl:call-template name="create-structure-number"/>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:call-template name="createLabelFromId">
      <xsl:with-param name="labelType">end</xsl:with-param>
    </xsl:call-template>
    <xsl:text>&#xa;\pend&#xa;</xsl:text>
    <xsl:if test="$p_position = $p_count">
      <xsl:text>&#xa;&#xa;\endnumbering</xsl:text>
      <xsl:text>&#xa;\end{</xsl:text>
      <xsl:value-of select="$text_language"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="createLabelFromId">
    <xsl:param name="labelType" />
    <xsl:if test="@xml:id">
      <xsl:text>%&#xa;</xsl:text>
      <xsl:choose>
        <xsl:when test="$labelType='start'">
          <xsl:text>\edlabelS{</xsl:text>
          <xsl:value-of select="@xml:id"/>
          <xsl:text>}%</xsl:text>
        </xsl:when>
        <xsl:when test="$labelType='end'">
          <xsl:text>\edlabelE{</xsl:text>
          <xsl:value-of select="@xml:id"/>
          <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>\edlabel{</xsl:text>
          <xsl:value-of select="@xml:id"/>
          <xsl:text>}</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="div[translate(@ana, '#', '') = $structure-types/*
                       and not(@n)]">
    <xsl:if test="my:isfalse($parallel-translation)">
      <!-- The parallel typesetting does not work well with manually added space
           because of syncronization -->
      <xsl:text>&#xa;\medbreak&#xa;</xsl:text>
    </xsl:if>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:param name="structure-types">
    <n>rationes-principales</n>
    <n>rationes-principales-pro</n>
    <n>rationes-principales-contra</n>
    <n>determinatio</n>
    <n>ad-rationes</n>
  </xsl:param>

  <xsl:function name="my:struct-elem">
    <xsl:param name="ana-value"/>
    <xsl:if test="translate($ana-value, '#', '') = $structure-types/*">
      <xsl:value-of select="true()"/>
    </xsl:if>
  </xsl:function>


  <!-- TODO: FIND a way of making references -->
  <!-- TODO: Make the number generation more generic (recursive) -->
  <xsl:template name="create-structure-number">
    <xsl:choose>
      <!-- p as structure element -->
      <xsl:when test="my:struct-elem(@ana)">
        <xsl:call-template name="print-structure-number">
          <xsl:with-param name="section-number">
            <xsl:number select="." count="div[my:struct-elem(@ana)]|p[my:struct-elem(@ana)]"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <!-- p as child of structure div -->
      <xsl:when test="ancestor::div[my:struct-elem(@ana)] and
                      parent::div[my:struct-elem(@ana)]">
        <xsl:call-template name="print-structure-number">
          <xsl:with-param name="section-number">
            <xsl:number select="ancestor::div[my:struct-elem(@ana)]"
                        count="div[my:struct-elem(@ana)]|p[my:struct-elem(@ana)]"/>
            <xsl:if test="not(@ana = '#structure-head')">
              <xsl:text>.</xsl:text>
              <xsl:number select="." count="p[not(@ana = '#structure-head')]|div"/>
            </xsl:if>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <!-- p inside div inside structure div -->
      <xsl:when test="ancestor::div[my:struct-elem(@ana)] and
                      parent::div[not(my:struct-elem(@ana))]">
        <xsl:if test="position() = 1">
          <xsl:call-template name="print-structure-number">
            <xsl:with-param name="section-number">
              <xsl:number select="ancestor::div[my:struct-elem(@ana)]"
                          count="div[my:struct-elem(@ana)]|p[my:struct-elem(@ana)]"/>
              <xsl:text>.</xsl:text>
              <xsl:number select="parent::div" count="div|p"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <!-- No structure number should be printed, so just make a linebreak -->
      <xsl:otherwise>
        <xsl:text>&#xa;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template name="print-structure-number">
    <xsl:param name="section-number"/>
    <xsl:if test="$section-number">
      <xsl:text>\no{</xsl:text>
      <xsl:value-of select="$section-number"/>
      <xsl:text>}%
      </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- INLINE ELEMENTS -->
  <!-- Wrap supplied, secluded, notes, and unclear in appropriate tex macros -->
  <xsl:template match="supplied">
    <xsl:choose>
      <xsl:when test="@ana='#meta-text'">
        <xsl:text>\metatext{</xsl:text>
      </xsl:when>
      <xsl:when test="@ana='#in-vacuo'">
        <xsl:text>\suppliedInVacuo{</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\supplied{</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="surplus">\secluded{<xsl:apply-templates/>}</xsl:template>
  <xsl:template match="unclear">\emph{<xsl:apply-templates/> [?]}</xsl:template>
  <xsl:template match="desc">\emph{<xsl:apply-templates/>}</xsl:template>
  <xsl:template match="abbr">\emph{<xsl:apply-templates/>}</xsl:template>
  <xsl:template match="app//mentioned">\emph{<xsl:apply-templates/>}</xsl:template>
  <xsl:template match="mentioned">`<xsl:apply-templates/>'</xsl:template>
  <xsl:template match="sic[@ana='#crux']">\corruption{<xsl:apply-templates/>}</xsl:template>
  <xsl:template match="note">\footnote{<xsl:apply-templates/>}</xsl:template>
  <xsl:template match="gap[@type='lacuna']">\lacuna{}</xsl:template>

  <xsl:template match="rdg/cb | rdg/pb">
    <xsl:text>|</xsl:text>
  </xsl:template>

  <xsl:template match="pb | cb" name="createPageColumnBreak">
    <xsl:param name="context" select="."/>
    <xsl:param name="withIndicator" select="true()"/>
    <xsl:param name="inParallelText" />
    <xsl:param name="with-siglum" select="true()"/>
    <xsl:if test="not($inParallelText)">
      <xsl:for-each select="$context">
        <xsl:choose>
          <xsl:when test="self::pb">
            <xsl:if test="$withIndicator">
              <xsl:text>\textnormal{|}</xsl:text>
            </xsl:if>
            <xsl:if test="not(parent::rdg)">
              <xsl:text>\ledsidenote{</xsl:text>
            </xsl:if>
            <xsl:if test="$with-siglum">
              <xsl:value-of select="translate(./@ed, '#', '')"/>
            </xsl:if>
            <xsl:text> </xsl:text>
            <xsl:value-of select="translate(./@n, '-', '')"/>
            <xsl:if test="following-sibling::*[1][self::cb]">
              <xsl:value-of select="following-sibling::cb[1]/@n"/>
            </xsl:if>
            <xsl:if test="not(parent::rdg)">
              <xsl:text>}</xsl:text>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="not(preceding-sibling::*[1][self::pb])">
              <xsl:if test="$withIndicator">
                <xsl:text>\textnormal{|}</xsl:text>
              </xsl:if>
              <xsl:if test="not(parent::rdg)">
                <xsl:text>\ledsidenote{</xsl:text>
              </xsl:if>
              <xsl:if test="$with-siglum">
                <xsl:value-of select="translate(./@ed, '#', '')"/>
              </xsl:if>
              <xsl:text> </xsl:text>
              <xsl:value-of select="translate(preceding::pb[./@ed = $context/@ed][1]/@n, '-', '')"/>
              <xsl:value-of select="./@n"/>
              <xsl:if test="not(parent::rdg)">
                <xsl:text>}</xsl:text>
              </xsl:if>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <xsl:template match="seg">
    <xsl:if test="@type='target'">
      <xsl:call-template name="createLabelFromId">
        <xsl:with-param name="labelType">start</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test="@type='target'">
      <xsl:call-template name="createLabelFromId">
        <xsl:with-param name="labelType">end</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- THE APPARATUS HANDLING -->
  <xsl:template match="app">
    <!-- First, check if we even need an apparatus entry: If the critical
         apparatus is disabled altogether or it's a spelling or insubstantial
         entry that is disabled, just print the content of the lem -->
    <xsl:choose>
      <xsl:when test="my:isfalse($create-critical-apparatus)">
        <xsl:apply-templates select="lem"/>
      </xsl:when>
      <xsl:when test="@type='variation-spelling'">
        <xsl:if test="my:istrue($ignore-spelling-variants)">
          <xsl:apply-templates select="lem"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>


        <!-- Two initial variables -->
        <!-- Store lemma text if it exists? -->
        <xsl:variable name="lemma_text">
          <xsl:choose>
            <xsl:when test="lem/cit[quote]">
              <xsl:value-of select="my:format-lemma(string-join(lem//quote[not(ancestor::bibl)], ''))" />
            </xsl:when>
            <xsl:when test="lem = ''"/>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="lem[@n]">
                  <xsl:value-of select="my:format-lemma(lem/@n)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="my:format-lemma(string-join(.//lem//text()[not(ancestor::rdg)], ''))" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Register a possible text anchor (for empty lemmas) -->
        <xsl:variable name="preceding_word" select="lem/@n"/>


        <!-- The entry proper -->
        <!-- The critical text -->
        <xsl:text>\edtext{</xsl:text>
        <xsl:apply-templates select="lem"/>
        <xsl:text>}{</xsl:text>

        <!-- The app lemma. Given in abbreviated or full length. -->
        <xsl:choose>
          <xsl:when test="count(tokenize($lemma_text, ' ')) &gt; 4">
            <xsl:text>\lemma{</xsl:text>
            <xsl:value-of select="tokenize($lemma_text, ' ')[1]"/>
            <xsl:text> \dots{} </xsl:text>
            <xsl:value-of select="tokenize($lemma_text, ' ')[last()]"/>
            <xsl:text>}</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>\lemma{</xsl:text>
            <xsl:value-of select="$lemma_text"/>
            <xsl:text>}</xsl:text>
          </xsl:otherwise>
        </xsl:choose>

        <!-- Make an applabel if the app note has an xml:id -->
        <xsl:if test="@xml:id">
          <xsl:text>\applabel{</xsl:text>
          <xsl:value-of select="@xml:id"/>
          <xsl:text>}</xsl:text>
        </xsl:if>

        <!-- The critical note itself. If lemma is empty, use the [nosep] option -->
        <xsl:choose>
          <xsl:when test="lem = ''">
            <xsl:text>\Bfootnote[nosep]{</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>\Bfootnote{</xsl:text>
          </xsl:otherwise>
        </xsl:choose>

        <!--
            This is the trick part. If we are actually in a <lem>-element instead of
            a <rdg>-element, it entails some changes in the handling of the
            apparatus note.
            We know that we are in a <lem>-element if it is given a reading type.
            TODO: This should check that it is one of the used reading types.
            TODO: Should all reading types be possible in the lemma? Any? It is
            implied by the possibility of having @wit in lemma.
        -->
        <xsl:if test="lem/@wit or lem/@source">
          <!-- This loop is stupid, but I need to have the lem-element as the root
               node when handling the variants. -->
          <xsl:for-each select="./lem">
            <xsl:call-template name="varianttype">
              <xsl:with-param name="lemma_text" select="$lemma_text" />
              <xsl:with-param name="fromLemma">1</xsl:with-param>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:if>
        <xsl:for-each select="rdg">
          <!-- This test is not good. Intention: If rdg = lemma, or it is
               explicitly said to be identical with the @corresp='#lemma', AND the
               apparatus should be negative, it should not print the entry. It
               gives problems with additions, where the test on identity between
               lemma and reading returns true, but I don't what that (the
               reading contains an <add>. -->
          <xsl:if test="not($lemma_text = my:format-lemma(.) or @copyOf = 'preceding::lem')
                        or unclear
                        or @type = 'correction-addition'
                        or my:istrue($positive-apparatus)">
            <xsl:call-template name="varianttype">
              <xsl:with-param name="preceding_word" select="$preceding_word"/>
              <xsl:with-param name="lemma_text" select="$lemma_text" />
              <xsl:with-param name="fromLemma">0</xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </xsl:for-each>

        <!-- Handling of apparatus notes. -->
        <!-- Test: If notes as included, and there is a note in the apparatus:
             either make a separate app entry (Cfootnote), if
             $app-notes-in-separate-apparatus is true, otherwise, just include it in
             the current app (Bfootnote).
             If there is no note, or they have been excluded, just close the app.
        -->
        <xsl:choose>
          <!-- First: is there any notes, and they are not excluded -->
          <xsl:when test="./note and my:istrue($include-app-notes)">

            <xsl:choose>
              <!-- Create separate note apparatus with Cfootnote -->
              <xsl:when test="my:istrue($app-notes-in-separate-apparatus)">
                <!-- Close current entry and create new. -->
                <xsl:text>}}</xsl:text>

                <!-- The critical text, which is always empty as we have already
                     made the text entry -->
                <xsl:text>\edtext{}{</xsl:text>

                <!-- The app lemma. Given in abbreviated or full length. -->
                <xsl:choose>
                  <xsl:when test="count(tokenize($lemma_text, ' ')) &gt; 4">
                    <xsl:text>\lemma{</xsl:text>
                    <xsl:value-of select="tokenize($lemma_text, ' ')[1]"/>
                    <xsl:text> \dots{} </xsl:text>
                    <xsl:value-of select="tokenize($lemma_text, ' ')[last()]"/>
                    <xsl:text>}</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>\lemma{</xsl:text>
                    <xsl:value-of select="$lemma_text"/>
                    <xsl:text>}</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>

                <!-- Notes in the apparatus are put as endnotes. If lemma is
                     empty, use the [nosep] option -->
                <xsl:choose>
                  <xsl:when test="lem = ''">
                    <xsl:text>\Aendnote[nosep]{</xsl:text>
                    <xsl:text> \emph{after} </xsl:text>
                    <xsl:value-of select="lem/@n"/>
                    <xsl:text>: </xsl:text>
                    <xsl:apply-templates select="note"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>\Aendnote{</xsl:text>
                    <xsl:apply-templates select="note"/>
                  </xsl:otherwise>
                </xsl:choose>

                <!-- Close the Aendnote -->
                <xsl:text>}}</xsl:text>
              </xsl:when>

              <!-- Don't make a separate apparatus -->
              <xsl:otherwise>
                <xsl:text>Note: </xsl:text>
                <xsl:apply-templates select="note"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>

          <!-- There is not note, or it is excluded, so we just close the Bfootnote -->
          <xsl:otherwise>
            <xsl:text>}}</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="varianttype">
    <xsl:param name="lemma_text" />
    <xsl:param name="fromLemma" />
    <xsl:param name="preceding_word" />

    <xsl:choose>

      <!-- VARIATION READINGS -->
      <!-- variation-substance -->
      <xsl:when test="@type = 'variation-substance' or not(@type)">
        <xsl:if test="not($lemma_text = my:format-lemma(.))">
          <xsl:apply-templates select="."/>
        </xsl:if>
        <xsl:text> </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- variation-orthography -->
      <xsl:when test="@type = 'variation-orthography'">
        <xsl:if test="my:isfalse($ignore-spelling-variants)">
          <xsl:apply-templates select="."/>
          <xsl:text> </xsl:text>
          <xsl:call-template name="get_witness_siglum"/>
        </xsl:if>
      </xsl:when>

      <!-- variation-inversion -->
      <xsl:when test="@type = 'variation-inversion'">
        <xsl:choose>
          <xsl:when test="./seg">
            <xsl:apply-templates select="./seg[1]"/>
            <xsl:text> \emph{ante} </xsl:text>
            <xsl:apply-templates select="./seg[2]"/>
            <xsl:text> \emph{scr.} </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>\emph{inv.} </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- variation-present -->
      <xsl:when test="@type = 'variation-present'">
        <xsl:choose>
          <xsl:when test="@cause = 'repetition'">
            <xsl:if test="not($lemma_text)">
              <!--
                  If there is no lemma (I think both might be intuitive to
                  different people), use the reading, which will be identical to
                  the preceding word, as it is an iteration
              -->
              <xsl:value-of select="."/>
            </xsl:if>
            <xsl:text> \emph{iter.} </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="process_empty_lemma_reading">
              <xsl:with-param name="reading_content" select="."/>
              <xsl:with-param name="preceding_word" select="$preceding_word"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- variation-absent -->
      <!-- TODO: Expand further in accordance with documentation -->
      <xsl:when test="@type = 'variation-absent'">
        <xsl:text>\emph{om.} </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- variation-choice -->
      <!--
          TODO: This also needs implementation of hands, location and segment
          order. I thinks it better to start with a bare bones implementation
          and go from there
      -->
      <xsl:when test="@type = 'variation-choice'">
        <xsl:variable name="seg_count" select="count(choice/seg)"/>
        <xsl:for-each select="choice/seg">
          <xsl:choose>
            <xsl:when test="position() &lt; $seg_count">
              <xsl:choose>
                <xsl:when test="position() = ($seg_count - 1)">
                  <xsl:apply-templates select="."/>
                  <xsl:text> \emph{et} </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="."/>
                  <xsl:text>, </xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="."/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:text> </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- CORRECTIONS -->
      <!-- correction-addition -->
      <xsl:when test="@type = 'correction-addition'">
        <xsl:choose>
          <!-- addition made in <lem> element -->
          <xsl:when test="$fromLemma = 1">
            <xsl:if test="not($lemma_text = my:format-lemma(.))">
              <xsl:apply-templates select="."/>
            </xsl:if>
          </xsl:when>
          <!-- addition not in lemma element -->
          <xsl:otherwise>
            <xsl:choose>
              <!-- empty lemma text handling -->
              <xsl:when test="$lemma_text = ''">
                <xsl:call-template name="process_empty_lemma_reading">
                  <xsl:with-param name="reading_content" select="add"/>
                  <xsl:with-param name="preceding_word" select="$preceding_word"/>
                </xsl:call-template>
              </xsl:when>
              <!-- reading ≠ lemma -->
              <xsl:when test="not($lemma_text = my:format-lemma(add))">
                <xsl:apply-templates select="add"/>
              </xsl:when>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="getLocation" />
        <xsl:text> </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- manual -->
      <xsl:when test="@type = 'manual'">
        <xsl:apply-templates select="."/>
        <xsl:text> </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>


      <!-- correction-deletion -->
      <!-- TODO: Implement handling of del@rend attribute -->
      <xsl:when test="@type = 'correction-deletion'">
        <xsl:call-template name="process_empty_lemma_reading">
          <xsl:with-param name="reading_content" select="del"/>
          <xsl:with-param name="preceding_word" select="$preceding_word"/>
        </xsl:call-template>
        <xsl:text> \emph{del.} </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- correction-substitution -->
      <!-- TODO: Take @rend and @place into considerations -->
      <xsl:when test="@type = 'correction-substitution'">
        <xsl:choose>
          <!-- Wit is corrected to something identical to the lemma. -->
          <xsl:when test="$lemma_text = my:format-lemma(subst/add)">
            <xsl:apply-templates select="subst/del"/>
            <xsl:text> \emph{a.c.} </xsl:text>
          </xsl:when>
          <!-- Wit differs from lemma -->
          <xsl:otherwise>
            <xsl:choose>
              <!-- empty lemma text handling -->
              <xsl:when test="$lemma_text = ''">
                <xsl:call-template name="process_empty_lemma_reading">
                  <xsl:with-param name="reading_content" select="subst/add"/>
                  <xsl:with-param name="preceding_word" select="$preceding_word"/>
                </xsl:call-template>
              </xsl:when>
              <!-- lemma has content -->
              <xsl:otherwise>
                <xsl:apply-templates select="subst/add"/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text> \emph{corr. ex} </xsl:text>
            <xsl:apply-templates select="subst/del"/>
            <xsl:text> </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- correction-transposition -->
      <xsl:when test="@type = 'correction-transposition'">
        <xsl:choose>
          <xsl:when test="subst/del/seg[@n]">
            <xsl:apply-templates select="subst/del/seg[@n = 1]"/>
            <xsl:text> \emph{ante} </xsl:text>
            <xsl:apply-templates select="subst/del/seg[@n = 2]"/>
            <xsl:text> \emph{transp.} </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="$lemma_text = my:format-lemma(subst/add)">
                <xsl:text> \emph{inv. a.c.} </xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="del/subst/add"/>
                <xsl:text> \emph{corr. ex} </xsl:text>
                <xsl:apply-templates select="del/subst/del"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- correction-cancellation subtypes -->
      <!-- TODO: They need to handle hands too -->

      <!-- deletion-of-addition -->
      <xsl:when test="@type = 'deletion-of-addition'">
        <xsl:call-template name="process_empty_lemma_reading">
          <xsl:with-param name="reading_content" select="del/add"/>
          <xsl:with-param name="preceding_word" select="$preceding_word"/>
        </xsl:call-template>
        <xsl:text> \emph{add. et del.} </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- deleton-of-deletion -->
      <xsl:when test="@type = 'deletion-of-deletion'">
        <xsl:apply-templates select="del/del"/>
        <xsl:text> \emph{del. et scr.} </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- deletion-of-substitution -->
      <xsl:when test="@type = 'deletion-of-substitution'">
        <xsl:apply-templates select="del/subst/add"/>
        <xsl:text> \emph{corr. ex} </xsl:text>
        <xsl:apply-templates select="del/subst/del"/>
        <xsl:text> \emph{et deinde correctionem revertavit} </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- substitution-of-addition -->
      <xsl:when test="@type = 'substitution-of-addition'">
        <xsl:apply-templates select="subst/del/add"/>
        <xsl:text> \emph{add. et del. et deinde} </xsl:text>
        <xsl:apply-templates select="subst/add"/>
        <xsl:text> \emph{scr.} </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:when>

      <!-- CONJECTURES -->
      <!-- conjecture-supplied -->
      <xsl:when test="@type = 'conjecture-supplied'">
        <xsl:choose>
          <!-- If we come from lemma element, don't print the content of it -->
          <xsl:when test="$fromLemma = 1"/>
          <!-- Otherwise, just print -->
          <xsl:otherwise>
            <xsl:apply-templates select="supplied/text()"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@source">
          <xsl:text> \emph{suppl.}</xsl:text>
          <xsl:text> </xsl:text>
          <xsl:call-template name="get_witness_siglum"/>
        </xsl:if>
      </xsl:when>

      <!-- conjecture-removed -->
      <xsl:when test="@type = 'conjecture-removed'">
        <xsl:choose>
          <!-- empty lemma text handling -->
          <xsl:when test="$lemma_text = ''">
            <xsl:call-template name="process_empty_lemma_reading">
              <xsl:with-param name="reading_content" select="surplus/node()"/>
              <xsl:with-param name="preceding_word" select="$preceding_word"/>
            </xsl:call-template>
          </xsl:when>
          <!-- If we come from lemma element, don't print the content of it -->
          <xsl:when test="$fromLemma = 1"/>
          <xsl:otherwise>
            <xsl:apply-templates select="supplied"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> \emph{secl.}</xsl:text>
        <xsl:if test="@source">
          <xsl:text> </xsl:text>
          <xsl:call-template name="get_witness_siglum"/>
        </xsl:if>
      </xsl:when>

      <!-- conjecture-corrected -->
      <xsl:when test="@type = 'conjecture-corrected'">
        <xsl:choose>
          <!-- If we come from lemma element, don't repeat the content -->
          <xsl:when test="$fromLemma = 1"/>
          <xsl:otherwise>
            <xsl:apply-templates select="corr"/>
            <xsl:text> \emph{conj.} </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@source">
          <xsl:text> </xsl:text>
          <xsl:call-template name="get_witness_siglum"/>
        </xsl:if>
      </xsl:when>

      <!-- fallback: If no type matches, print the content and the siglum. -->
      <xsl:otherwise>
        <xsl:apply-templates select="."/><xsl:text> </xsl:text>
        <xsl:call-template name="get_witness_siglum"/>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="cb|pb">
      <xsl:text>(</xsl:text>
      <xsl:call-template name="createPageColumnBreak">
        <xsl:with-param name="withIndicator" select="false()"/>
        <xsl:with-param name="context" select="cb|pb"/>
        <xsl:with-param name="with-siglum" select="false()"/>
      </xsl:call-template>
      <xsl:text>)</xsl:text>
    </xsl:if>

    <xsl:if test="note">
      <xsl:text> (</xsl:text>
      <xsl:apply-templates select="note"/>
      <xsl:text>)</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- READING TEMPLATES -->
  <!-- Erasures in readings -->
  <!-- <xsl:template match="rdg/space[@reason = 'erasure']"> -->
  <!--   <xsl:text>\emph{ras.</xsl:text> -->
  <!--   <xsl:if test="@extent"> -->
  <!--     <xsl:text> </xsl:text> -->
  <!--     <xsl:call-template name="getExtent"/> -->
  <!--   </xsl:if> -->
  <!--   <xsl:text>}</xsl:text> -->
  <!-- </xsl:template> -->

  <!-- APPARATUS HELPER TEMPLATES -->
  <xsl:template name="process_empty_lemma_reading">
    <xsl:param name="reading_content"/>
    <xsl:param name="preceding_word"/>
    <xsl:value-of select="$reading_content"/>
    <xsl:text> \emph{post} </xsl:text>
    <xsl:value-of select="$preceding_word"/>
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template name="get_witness_siglum">
    <xsl:variable name="appnumber"><xsl:number level="any" from="tei:text"/></xsl:variable>
    <!-- First fill in witness references -->
    <xsl:variable name="witness-id" select="translate(@wit, '#', '')"/>
    <!-- Check for sibling witDetail elements and insert content -->
    <xsl:if test="following-sibling::witDetail[translate(@wit, '#', '')=$witness-id]">
      <xsl:text>\emph{</xsl:text>
      <xsl:apply-templates select="following-sibling::witDetail[translate(@wit, '#', '')=$witness-id]"/>
      <xsl:text>} </xsl:text>
    </xsl:if>
    <!-- Then note if the reading is uncertain -->
    <xsl:if test="unclear">
      <xsl:text> \emph{lectio incerta} </xsl:text>
    </xsl:if>
    <xsl:value-of select="translate(@wit, '#', '')"/>
    <xsl:text> </xsl:text>
    <!-- Then fill in other sources -->
    <xsl:variable name="source-id" select="translate(@source, '#', '')"/>
    <xsl:choose>
      <xsl:when test="//tei:bibl[@xml:id=$source-id]/@rend">
        <xsl:value-of select="//tei:bibl[@xml:id=$source-id]/@rend"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$source-id"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test=".//@hand">
      <xsl:text>\hand{</xsl:text>
      <xsl:for-each select=".//@hand">
        <xsl:value-of select="translate(., '#', '')"/>
        <xsl:if test="not(position() = last())">, </xsl:if>
      </xsl:for-each>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="my:istrue($apparatus-numbering)">
      <xsl:text> n</xsl:text><xsl:value-of select="$appnumber"></xsl:value-of>
    </xsl:if>
    <xsl:if test="following-sibling::*[1][self::rdg]">
      <xsl:value-of select="$app-entry-separator"/>
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="getExtent">
    <xsl:value-of select=".//@extent" />
    <xsl:choose>
      <xsl:when test=".//@extent &lt; 2">
        <xsl:choose>
          <xsl:when test=".//@unit = 'letters'"> litt.</xsl:when>
          <xsl:when test=".//@unit = 'words'"> verb.</xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test=".//@unit = 'letters'"> litt.</xsl:when>
          <xsl:when test=".//@unit = 'words'"> verb.</xsl:when>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="getLocation">
    <xsl:choose>
      <xsl:when test="add/@place='above-line'">
        <xsl:text> \emph{sup. lin.}</xsl:text>
      </xsl:when>
      <xsl:when test="contains(add/@place, 'margin')">
        <xsl:text> \emph{in marg.}</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- REFERENCES -->
  <xsl:template match="cit">
    <xsl:text>\edtext{</xsl:text>
    <xsl:apply-templates select="ref|quote"/>
    <xsl:text>}</xsl:text>
    <xsl:text>{\lemma{</xsl:text>
    <xsl:if test="my:istrue($app-fontium-quote)">
      <xsl:choose>
        <xsl:when test="count(tokenize(normalize-space(quote), ' ')) &gt; 4">
          <xsl:value-of select="tokenize(normalize-space(quote), ' ')[1]"/>
          <xsl:text> \dots{} </xsl:text>
          <xsl:value-of select="tokenize(normalize-space(quote), ' ')[last()]"/>
          <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="normalize-space(quote)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:text>}</xsl:text>
    <xsl:choose>
      <xsl:when test="my:istrue($app-fontium-quote)">
        <xsl:text>\Afootnote{</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\Afootnote[nosep]{</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="bibl"/>
    <xsl:apply-templates select="note"/>
    <xsl:text>}}</xsl:text>
  </xsl:template>

  <xsl:template match="cit/bibl">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="note/bibl">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="ref">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="cit/note">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="quote">
    <xsl:choose>
      <xsl:when test="@type='paraphrase'">
        <xsl:apply-templates />
      </xsl:when>
      <xsl:when test="@type='lemma'">
        <xsl:text>\lemmaQuote{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="@type='direct' or not(@type)">
        <xsl:text> \enquote{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ref/name">
    <xsl:text>\name{</xsl:text>
    <xsl:call-template name="name"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template name="name" match="name">
    <xsl:variable name="nameid" select="substring-after(./@ref, '#')"/>
    <xsl:apply-templates/>
    <xsl:text>\index[persons]{</xsl:text><xsl:value-of select="document($name-list-file)//tei:person[@xml:id=$nameid]/tei:persName[1]"/><xsl:text>} </xsl:text>
  </xsl:template>

  <xsl:template match="title">
    <xsl:text>\worktitle{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <xsl:choose>
      <xsl:when test="./@ref">
        <xsl:variable name="workid" select="substring-after(./@ref, '#')"/>
        <xsl:variable name="canonical-title" select="document($work-list-file)//tei:bibl[@xml:id=$workid]/tei:title[1]"/>
        <xsl:text>\index[works]{</xsl:text>
        <xsl:choose>
          <xsl:when test="$canonical-title">
            <xsl:value-of select="$canonical-title"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message>No work with the id <xsl:value-of select="$workid"/> in workslist file (<xsl:value-of select="$work-list-file"/>)</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="no">No reference given for title/<xsl:value-of select="."/>.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


</xsl:stylesheet>
