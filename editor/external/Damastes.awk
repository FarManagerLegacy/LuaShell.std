# Damastes.awk: aligns delimited text for easier perception; may also cut long fields' content.
#
# Copyright 2005-2021 Ruslan Khamidullin
#
#  This file is part of Damastes.
#
#  Damastes is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# Version    : 1.1
# Date       : 2021-03-30
# Author     : HaRT
# History    :
#  2005-11-25: v.0.1: implemented the simplest alignment
#  2005-11-30: v.0.2: implemented sPadTill & sCutFrom parameters
#  2005-12-02: v.0.3: implemented sCutFlag parameter
#  2005-12-09: v.0.4: released as a single code file under GPL
#  2005-12-20:      : implemented cutting a column out
#  2005-12-20:      : reformatted dates in this document
#  2005-12-22:      : stopped storing useless empty values
#  2006-01-11:      : updated copyright statement; slightly restructured this doc
#  2006-02-15:      : fixed empty lines processing
#  2006-02-15:      : added support for the sPadding parameter
#  2006-03-22:      : mentioned the RS, FS, ORS, OFS parameters in the documentation below
#  2006-03-23: v.1.0: published
#  2009-08-20:      : numbered ToDo items; added ToDo 4
#  2009-08-24:      : slightly reformatted this documentation
#  2009-09-04:      : converted to UNIX-style EOLs; added ToDo 5
#  2013-02-26:      : added ToDo 6-7
#  2021-03-30: v.1.1: published
#
# Parameters :
#  RS, FS, ORS, OFS - input/ output records separators/ terminators (see AWK documentation)
#  sCutFrom - "cut from the position"
#  sPadTill - "pad to the position"
#    sCutFrom and sPadTill are one char per column: 0 (cut out), miN, Left, Average, Right, maX.
#    The last letter propagates to the rest of columns. Default: "X".
#  sCutFlag - the string to put where characters are cut
#    Empty string will cause usage of the default value. Default: "".
#  sPadding - the string to fill the padding. Default: " ".
#
# ToDo       :
#  1. Support for cutting runs of empty rows/ columns
#  2. sAlign - control alignment. One char per column: Left, Center, Right, Justified. Default: "L".
#  3. Support for fixed column widths
#  4. Support for statistics with distant values removed
#  5. Include the `cut out' functionality into the main documentation
#  6. Support cutting/retaining line number ranges, e.g. "5,10,17-54_23-26,34"
#  7. Support reversed line number ranges, like in "svn log -r HEAD:1" (cover "tac"-like features)

function DefPadTill() { return "X" }
function DefCutFrom() { return "X" }
function DefCutFlag() { return "" }
function DefPadding() { return " " }

######################################## Common functions

function round( v ) # numerical rounding
{
  v += 0  # make it numeric
  return int( v + ( v >= 0 ? 0.5 : -0.5 ) )
}

function num_min( n1, n2 ) { # minimum of two numbers
  n1 += 0; n2 += 0; # make numeric
  if ( n1 <= n2 )
    return n1
  else
    return n2
}

function num_max( n1, n2 ) # maximum of two numbers
{
  n1 += 0; n2 += 0; # make numeric
  if ( n1 >= n2 )
    return n1
  else
    return n2
}

# calculate the average given the the number and sum of values
function m_avg( nValues, sumValues )
{
  nValues += 0; sumValues += 0; # make them numeric
  return sumValues / num_max( nValues, 1 )
}

# calculate the dispersion given the number of values, their sum and sum of their squares
function m_dspr( nValues, sumValues, sumSquares        , avg )
{
  nValues += 0; sumValues += 0; sumSquares += 0  # make them numeric
  nValues = ( nValues <= 0 ) ? 1 : ( nValues < 2 ) ? 2 : nValues
  avg = m_avg( nValues, sumValues ) # an average
  return ( sumSquares - 2 * avg * sumValues + nValues * avg * avg ) / num_max( nValues - 1, 1 )
}

# fill the given width by repeating the given string
function Pad( sSrc, nLenDst, nLenSrc        , sRes, sAkk, nMod, nInt, nBit )
{
  if ( ! ( nLenDst += 0 ) )
    return ""

  if ( "" == nLenSrc )
    nLenSrc = length( sSrc )
  else
    nLenSrc += 0

  if ( ! nLenSrc )
    return # error

  sRes = ""
  sAkk = sSrc
  nMod = nLenDst % nLenSrc
  for ( nInt = ( nLenDst - nMod ) / nLenSrc; nInt; nInt = ( nInt - nBit ) / 2 )
  {
    if ( nBit = nInt % 2 )
      sRes = sRes sAkk
    sAkk = sAkk sAkk
  }

  sRes = sRes substr( sSrc, 1, nMod )
  return sRes
}

######################################## Specific functions

# GetColumnChar: returns sChars[iColumn] if any and sCharDef otherwise
#  sChars: source string; may be empty
#  iColumn: positive integer
#  sCharDef: only the first char is used (if any)
#  iLen: may be omitted
function GetColumnChar( sChars, iColumn, sCharDef, iLen )
{
  iColumn = round( iColumn ) # for imprecise values

  if ( iColumn < 1 )
    return ""

  if ( iLen == "" )
    iLen = length( sChars ) # for pre-calculated lengths
  else
    iLen = round( iLen ) # for imprecise values

  if ( iLen < 1 )
    return substr( sCharDef, 1, 1 )

  return substr( sChars, num_min( iLen, iColumn), 1 )
}

# GetWidth: relies upon global arrays aMin, aMax, aS0, aS1, aS2
function GetWidth( sChar, iNF )
{
  iLen = 0 # for "0" and invalid values
  if ( sChar ~ /[Nn]/ )
    iLen = aMin [ iNF ]
  else
  if ( sChar ~ /[Xx]/ )
    iLen = aMax [ iNF ]
  else
  {
    dMean = m_avg( aS0 [ iNF ], aS1 [ iNF ] )
    dDspr = sqrt( m_dspr( aS0 [ iNF ], aS1 [ iNF ], aS2 [ iNF ] ) )

    if ( sChar ~ /[Aa]/ )
      iSign = 0
    if ( sChar ~ /[Ll]/ )
      iSign = -1
    if ( sChar ~ /[Rr]/ )
      iSign = +1

    iLen = round( dMean + iSign * dDspr )
  }

  return iLen
}

BEGIN \
{
  if ( sCutFlag == "" )
    sCutFlag = DefCutFlag()

  if ( sPadding == "" )
    sPadding = DefPadding()

  iLenPadTill = length( sPadTill )
  iLenCutFrom = length( sCutFrom )
  iLenCutFlag = length( sCutFlag )
}

{
  if ( NF > 0 )
    aFields [ NR ] = NF

  for ( iNF = 1; iNF <= NF; ++ iNF )
  {
    if ( $iNF != "" )
      aFields [ NR, iNF ] = $iNF

    iLenCurr = length( $iNF )
    sCharPad = GetColumnChar( sPadTill, iNF, DefPadTill(), iLenPadTill )
    sCharCut = GetColumnChar( sCutFrom, iNF, DefCutFrom(), iLenCutFrom )
    sCat = sCharPad sCharCut

    if ( sCat ~ /[Nn]/ )
      if ( iNF in aMin )
        aMin [ iNF ] = num_min( aMin [ iNF ], iLenCurr )
      else
        aMin [ iNF ] = iLenCurr

    if ( sCat ~ /[Xx]/ )
      if ( iNF in aMax )
        aMax [ iNF ] = num_max( aMax [ iNF ], iLenCurr )
      else
        aMax [ iNF ] = iLenCurr

    if ( sCat ~ /[LlAaRr]/ )
    {
      aS0 [ iNF ] += 1
      aS1 [ iNF ] += iLenCurr
      aS2 [ iNF ] += iLenCurr * iLenCurr
    }
  }
}

END \
{
  for ( iNR = 1; iNR <= NR; ++ iNR )
  {
    NF = 0
    if ( iNR in aFields )
      NF = aFields [ iNR ]

    if ( ! NF )
      print ""

    for ( iNF = 1; iNF <= NF; ++ iNF )
    {
      iWidthMin = GetWidth( GetColumnChar( sPadTill, iNF, DefPadTill(), iLenPadTill ), iNF )
      iWidthMax = GetWidth( GetColumnChar( sCutFrom, iNF, DefCutFrom(), iLenCutFrom ), iNF )
      iWidthMax = num_max( iWidthMax, iLenCutFlag )

      sField = ""
      if ( ( iNR, iNF ) in aFields )
        sField = aFields [ iNR, iNF ]

      iLenCurr = length( sField )

      if ( iLenCurr > iWidthMax )
       sField = substr( sField, 1, num_max( 0, iWidthMax - iLenCutFlag ) ) sCutFlag

      printf( "%s%s%s", sField, Pad( sPadding, num_max( 0, iWidthMin - iLenCurr ) ), ( iNF < NF ) ? OFS : ORS )
    }
  }
}
