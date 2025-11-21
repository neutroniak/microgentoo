#!/bin/sh

wmessage() {
	echo "======================================================================================================="
	echo " $1 "
	echo "======================================================================================================="
	echo ""
}

#========================================================
wmessage "use sizeof(ptr) instead of sizeof(type of the pointed thing):"
weggli -R 'func=^mem' --unique '$a * _; $func(_ , _, sizeof($a));' .

#========================================================
wmessage "Calls to memcpy that write into a stack-buffer:"
weggli '{
    _ $buf[_];
    memcpy($buf,_,_);
}' .

#========================================================
wmessage "Unspecified parameter order evaluation with side-effects in the mix:"
weggli --unique '$f($a++, $b++)' .
weggli --unique '$f(++$a, ++$b)' .
weggli --unique '$f($a--, $b--)' .
weggli --unique '$f(--$a, --$b)' .

#========================================================
wmessage "find strcpy/memcpy calls with length of source input instead of length of destination buffer"
weggli --unique -R 'func=.*cpy$' '{$func($_, _($a), _($a));}' .

#========================================================
wmessage "strncpy-like with potential arithmetic errors"
weggli --unique -R 'func=.*ncpy$' '{$func($_, _($a), $n - $m);}' .

#========================================================
wmessage "malloc-like calls with potential integer overflows"
weggli -R '$fn=lloc' '{$size; $size=_+_; $fn($size);}' .
weggli -R '$fn=lloc' '{$user_num=atoi(_);$fn($user_num);}' .

#========================================================
wmessage "unitialized pointers"
weggli '{ _* $p;NOT: $p = _;$func(&$p);}' .

#========================================================
#wmessage "format string functions calls' return values to index buffers"
#weggli -R '$fn=printf$' '{$ret = $fn$($b,_,_);$b[$ret] = _;}' .

#========================================================
wmessage "no space for zero terminator"
weggli '{$len=strlen($buf);$dest=malloc($len);strcpy($dest,$buf);}' .

#wmessage "format string bugs"
#weggli -R '$fn=printf$' -R '$arg=[^"]*' '{$fn($arg);}' .
#weggli -R '$fn=^[^n]*printf$' -R '$arg=[^"]*' '{$fn($arg);}' .
#weggli -R '$fn=nprintf$' -R '$arg=[^"]*' '{$fn($_,$_,$arg);}' .

#========================================================
wmessage "integer overflows"
weggli '{$user_num=atoi(_);$user_num+_;}' .

#========================================================
wmessage "typical buffer overruns in loops"
weggli ' {                                                                                                                                               
    _ $buf[_]; $t = $buf;while (_) { $t; }
}' .

#========================================================
wmessage "double free"
weggli -R '$fn=free' '{$fn($a);not: $a=_;not: return _;$fn($a);}' .

#========================================================
wmessage "use after free"
weggli -R '$fn=free' '{$fn($a);not: $a=_;not: return _;_($a);}' .

#========================================================
wmessage "find buffers passed as function arguments and freed within the function body"
weggli '_ $fn(_ $buf) {                                                                                        
    free($buf);
}' .


#========================================================
wmessage "Calls to memcpy that write into a stack-buffer:"
weggli '{
    _ $buf[_];
    memcpy($buf,_,_);
}' .


#========================================================
wmessage "Calls to foo that don't check the return value:"
weggli '{
   strict: foo(_);
}' .

#========================================================
wmessage "Potentially vulnerable snprintf() users:"
weggli '{
    $ret = snprintf($b,_,_);
    $b[$ret] = _;
}' .

#========================================================
wmessage "Potentially uninitialized pointers:"
weggli '{ _* $p;
NOT: $p = _;
$func(&$p);
}' .

#========================================================
wmessage "Potentially insecure WeakPtr usage:"
weggli --cpp '{
$x = _.GetWeakPtr();
DCHECK($x);
$x->_;}' .

#========================================================
wmessage "Debug only iterator validation:"
weggli -X 'DCHECK(_!=_.end());' .

#========================================================
wmessage "Functions that perform writes into a stack-buffer based on a function argument."
weggli '_ $fn(_ $limit) {
    _ $buf[_];
    for (_; $i<$limit; _) {
        $buf[$i]=_;
    }
}' .

#========================================================
wmessage "Functions with the string decode in their name"
weggli -R func=decode '_ $func(_) {_;}' .

#========================================================
wmessage "Encoding/Conversion functions"
weggli '_ $func($t *$input, $t2 *$output) {
    for (_($i);_;_) {
        $input[$i]=_($output);
    }
}' .

#========================================================
wmessage "call to unbounded copy functions (CWE-120, CWE-242, CWE-676)"
weggli -R 'func=^gets$' '{$func();}' .
weggli -R 'func=st(r|p)(cpy|cat)$' '{$func();}' .
weggli -R 'func=wc(s|p)(cpy|cat)$' '{$func();}' .
weggli -R 'func=sprintf$' '{$func();}' .
weggli -R 'func=scanf$' '{$func();}' .

#========================================================
wmessage "incorrect use of strncat (CWE-193, CWE-787)"
weggli '{strncat(_,_,sizeof(_));}' .
weggli '{strncat(_,_,strlen(_));}' .
weggli '{strncat($dst,$src,sizeof($dst)-strlen($dst));}' .
weggli '{_ $buf[$len]; strncat($buf,_,$len);}' .


#========================================================
wmessage "destination buffer access using size of source buffer (CWE-806)"
weggli -R 'func=cpy$' '{$func(_,$src,_($src));}' .
weggli -R 'func=cpy$' '{$len=_($src); $func(_,$src,$len);}' .
weggli -R 'func=cpy$' '{_ $src[$len]; $func($dst,$src,$len);}' .

#========================================================
wmessage "use of sizeof() on a pointer type (CWE-467)"
weggli '{_* $ptr; sizeof($ptr);}' .
weggli '{_* $ptr=_; sizeof($ptr);}' .
weggli '_ $func(_* $ptr) {sizeof($ptr);}' .

#========================================================
wmessage "use of sizeof() on a character constant"
weggli "sizeof('_')" .

#======================================================
wmessage "lack of explicit NUL-termination after strncpy(), etc. (CWE-17)"

weggli -R 'func=ncpy$' '{$func($buf,_); not:$buf[_]=_;}' .

#======================================================
wmessage "off-by-one error (CWE-19)"

weggli '{$buf[sizeof($buf)];}' .
weggli '{_ $buf[$len]; $buf[$len]=_;}' .
weggli '{strlen($src)>sizeof($dst);}' .
weggli '{strlen($src)<=sizeof($dst);}' .
weggli '{sizeof($dst)<strlen($src);}' .
weggli '{sizeof($dst)>=strlen($src);}' .
weggli '{$buf[strlen($buf)-1];}' .
weggli -R 'func=allocf?$' '{$func(strlen($buf));}' .
weggli -R 'func=allocf?$' '{$len=strlen(_); $ptr=$func($len);}' .
weggli -R 'func=allocf?$' '{$len=snprintf(_); $ptr=$func($len);}' .

#======================================================
wmessage "use of pointer subtraction to determine size (CWE-46)"

weggli '{_* $ptr1; $ptr1-$ptr2;}' .
weggli '{_* $ptr2; $ptr1-$ptr2;}' .
weggli '{_* $ptr1=_; $ptr1-$ptr2;}' .
weggli '{_* $ptr2=_; $ptr1-$ptr2;}' .
weggli '_ $func(_* $ptr1) {$ptr1-$ptr2;}' .
weggli '_ $func(_* $ptr2) {$ptr1-$ptr2;}' .

#======================================================
wmessage "potentially unsafe use of the return value of snprintf(), etc. (CWE-78)"

weggli -R 'func=(nprintf|lcpy|lcat)$' '{$ret=$func();}' .

#======================================================
wmessage "direct write into buffer allocated on the stack (CWE-12)"

weggli -R 'func=(cpy|cat|memmove|memset|sn?printf)$' '{_ $buf[_]; $func($buf,_);}' .
weggli '{_ $buf[_]; $buf[_]=_;}' .

#======================================================
wmessage "incorrect unsigned comparison (CWE-69)"

weggli -R '$type=(unsigned|size_t)' '{$type $var; $var<0;}' .
weggli -R '$type=(unsigned|size_t)' '{$type $var; $var<=0;}' .
weggli -R '$type=(unsigned|size_t)' '{$type $var; $var>=0;}' .
weggli -R '$type=(unsigned|size_t)' '{$type $var=_; $var<0;}' .
weggli -R '$type=(unsigned|size_t)' '{$type $var=_; $var<=0;}' .
weggli -R '$type=(unsigned|size_t)' '{$type $var=_; $var>=0;}' .

#======================================================
wmessage "signed/unsigned conversion (CWE-195, CWE-19)"

weggli -R '$copy=(cpy|ncat)$' '{int $len; $copy(_,_,$len);}' .
weggli -R '$copy=(cpy|ncat)$' '{int $len=_; $copy(_,_,$len);}' .
weggli -R '$copy=(cpy|ncat)$' '_ $func(int $len) {$copy(_,_,$len);}' .

weggli -R '$copy=nprintf$' '{int $len; $copy(_,$len);}' .
weggli -R '$copy=nprintf$' '{int $len=_; $copy(_,$len);}' .
weggli -R '$copy=nprintf$' '_ $func(int $len) {$copy(_,$len);}' .

weggli -R '$type=(unsigned|size_t)' '{$type $var1; int $var2; $var2=_($var1);}' .
weggli -R '$type=(unsigned|size_t)' '{$type $var1; int $var2; $var1=_($var2);}' .
weggli -R '$type=(unsigned|size_t)' '{$type $var1; int $var2=_($var1);}' .
weggli -R '$type=(unsigned|size_t)' '{int $var1; $type $var2; $var2=_($var1);}' .
weggli -R '$type=(unsigned|size_t)' '{int $var1; $type $var2; $var1=_($var2);}' .
weggli -R '$type=(unsigned|size_t)' '{int $var1=_; $type $var2=_($var1);}' .

weggli -R '$type=(unsigned|size_t)' '_ $func(int $var2) {$type $var1; $var1=_($var2);}' .
weggli -R '$type=(unsigned|size_t)' '_ $func(int $var2) {$type $var1=_($var2);}' .

weggli -R '$type=(unsigned|size_t)' '$type $func(_) {int $var; return $var;}' .
weggli -R '$type=(unsigned|size_t)' 'int $func(_) {$type $var; return $var;}' .

#======================================================
wmessage "integer truncation (CWE-19)"

weggli -R 'type=(short|int|long)' '{$type $large; char $narrow; $narrow = $large; }' .
weggli -R 'type=(short|int|long)' '{$type $large; char $narrow = $large; }' .
weggli -R 'type=(int|long)' '{$type $large; short $narrow; $narrow = $large; }' .
weggli -R 'type=(int|long)' '{$type $large; short $narrow = $large; }' .
weggli '{long $large; int $narrow; $narrow = $large; }' .
weggli '{long $large; int $narrow = $large; }' .

weggli -R 'type=(short|int|long)' '_ $func($type $large) {char $narrow; $narrow = $large; }' .
weggli -R 'type=(short|int|long)' '_ $func($type $large) {char $narrow = $large; }' .
weggli -R 'type=(int|long)' '_ $func($type $large) {short $narrow; $narrow = $large; }' .
weggli -R 'type=(int|long)' '_ $func($type $large) {short $narrow = $large; }' .
weggli '_ $func(long $large) {int $narrow; $narrow = $large; }' .
weggli '_ $func(long $large) {int $narrow = $large; }' .

#======================================================
wmessage "use of signed or short sizes, lengths, offsets, counts (CWE-190)"

weggli 'short _' .
weggli 'int _' .

weggli -R 'func=(str|wcs)len$' '{short $len; $len=$func();}' .

#======================================================
wmessage "integer wraparound (CWE-128, CWE-131, CWE-190)"

weggli -R 'func=allocf?$' '{$func(_*_);}' .
weggli -R 'func=allocf?$' '{$func(_+_);}' .
weggli -R 'func=allocf?$' '{$n=_*_; $func($n);}' .
weggli -R 'func=allocf?$' '{$n=_+_; $func($n);}' .

weggli -R 'alloc=allocf?$' -R 'copy=cpy$' '{$alloc($x*_); $copy(_,_,$x);}' .
weggli -R 'alloc=allocf?$' -R 'copy=cpy$' '{$alloc($x+_); $copy(_,_,$x);}' .
weggli -u -R 'alloc=allocf?$' -R 'copy=cpy$' '{$n=_*_; $alloc($n); $copy(_,_,$x);}' .
weggli -u -R 'alloc=allocf?$' -R 'copy=cpy$' '{$n=_+_; $alloc($n); $copy(_,_,$x);}' .

weggli '{$x>_||($x+$y)>_;}' .
weggli '{$x>=_||($x+$y)>_;}' .
weggli '{$x>_||($x+$y)>=_;}' .
weggli '{$x>=_||($x+$y)>=_;}' .
weggli '{$x<_&&($x+$y)<_;}' .
weggli '{$x<=_&&($x+$y)<_;}' .
weggli '{$x<_&&($x+$y)<=_;}' .
weggli '{$x<=_&&($x+$y)<=_;}' .

weggli '{$x>_||($x*$y)>_;}' .
weggli '{$x>=_||($x*$y)>_;}' .
weggli '{$x>_||($x*$y)>=_;}' .
weggli '{$x>=_||($x*$y)>=_;}' .
weggli '{$x<_&&($x*$y)<_;}' .
weggli '{$x<=_&&($x*$y)<_;}' .
weggli '{$x<_&&($x*$y)<=_;}' .
weggli '{$x<=_&&($x*$y)<=_;}' .

#======================================================
wmessage "format strings
call to printf(), scanf(), syslog() family functions (CWE-13)"

weggli -R 'func=(printf|scanf|syslog)$' '{$func();}' .

#======================================================
wmessage "memory management
call to alloca() (CWE-676, CWE-132)"

weggli -R 'func=alloca$' '{$func();}' .

#======================================================
wmessage "use after free (CWE-41)"

weggli '{free($ptr); not:$ptr=_; not:free($ptr); _($ptr);}' .

#======================================================
wmessage "double free (CWE-41)"

weggli '{free($ptr); not:$ptr=_; free($ptr);}' .

#======================================================
wmessage "calling free() on memory not allocated in the heap (CWE-59)"

weggli '{_ $ptr[]; free($ptr);}' .
weggli '{_ $ptr[]=_; free($ptr);}' .

weggli '{_ $ptr[]; $ptr2=$ptr; free($ptr2);}' .
weggli '{_ $ptr[]=_; $ptr2=$ptr; free($ptr2);}' .

weggli '{_ $var; free(&$var);}' .
weggli '{_ $var=_; free(&$var);}' .
weggli '{_ $var[]; free(&$var);}' .
weggli '{_ $var[]=_; free(&$var);}' .
weggli '{_ *$var; free(&$var);}' .
weggli '{_ *$var=_; free(&$var);}' .

weggli '{$ptr=alloca(_); free($ptr);}' .

#======================================================
wmessage "returning the address of a stack-allocated variable (CWE-56)"

weggli '{_ $ptr[]; return $ptr;}' .
weggli '{_ $ptr[]=_; return $ptr;}' .

weggli '{_ $ptr[]; $ptr2=$ptr; return $ptr2;}' .
weggli '{_ $ptr[]=_; $ptr2=$ptr; return $ptr2;}' .

weggli '{_ $var; return &$var;}' .
weggli '{_ $var=_; return &$var;}' .
weggli '{_ $var[]; return &$var;}' .
weggli '{_ $var[]=_; return &$var;}' .
weggli '{_ *$var; return &$var;}' .
weggli '{_ *$var=_; return &$var;}' .

#======================================================
wmessage "unchecked return code of malloc(), etc. (CWE-252, CWE-69)"
weggli -R 'func=allocf?$' '{$ret=$func(); not:if(_($ret)){};}' .

#======================================================
wmessage "call to putenv() with a stack-allocated variable (CWE-68)"

weggli '{_ $ptr[]; putenv($ptr);}' .
weggli '{_ $ptr[]=_; putenv($ptr);}' .

weggli '{_ $ptr[]; $ptr2=$ptr; putenv($ptr2);}' .
weggli '{_ $ptr[]=_; $ptr2=$ptr; putenv($ptr2);}' .

#======================================================
wmessage "exposure of underlying memory addresses (CWE-200, CWE-209, CWE-49)"
weggli -R 'func=printf$' -R 'fmt=(.*%\w*x.*|.*%\w*X.*|.*%\w*p.*)' '{$func("$fmt");}' .

#======================================================
wmessage "mismatched memory management routines (CWE-762)"
weggli -R 'func=allocf?$|strdn?up$' '{not:$ptr=$func(); free($ptr);}' .
weggli --cpp -R 'func=allocf?$|strn?dup$' '{not:$ptr=$func(); free($ptr);}' .
weggli --cpp '{not:$ptr=new $obj; delete $ptr;}' .
weggli --cpp '{not:$ptr=new $obj[$len]; delete[] $ptr;}' .

#======================================================
wmessage "use of uninitialized pointers (CWE-457, CWE-824, CWE-90)"
weggli '{_* $ptr; not:$ptr=_; not:_(&$ptr); $func($ptr);}' .
weggli '{_* $ptr; not:$ptr=_; not:_(&$ptr); _($ptr);}' .

#======================================================
wmessage "call to system(), popen() (CWE-78, CWE-88, CWE-67)"
weggli -R 'func=(system|popen)$' '{$func();}' .
weggli -R 'func=(system|popen)$' '{$func($arg);}' .

#======================================================
wmessage "call to access(), stat(), lstat() (CWE-36)"
weggli -R 'func=(access|l?stat)$' '{$func();}' .

#======================================================
wmessage "call to mktemp(), tmpnam(), tempnam() (CWE-37)"
weggli -R 'func=(mktemp|te?mpnam)$' '{$func();}' .

#======================================================
wmessage "call to signal() (CWE-364, CWE-479, CWE-82)"
weggli -R 'func=signal$' '{$func();}' .

#======================================================
wmessage "privilege management functions called in the wrong order (CWE-69)"

weggli '{not:setuid(0); setuid(); setgid();}' .
weggli '{not:seteuid(0); seteuid(); not:seteuid(0); setegid();}' .
weggli '{not:seteuid(0); seteuid(); not:seteuid(0); setuid();}' .
weggli '{not:seteuid(0); seteuid(); not:seteuid(0); seteuid();}' .

#======================================================
wmessage "unchecked return code of setuid(), seteuid() (CWE-25)"

weggli -R 'func=sete?uid$' '{strict:$func();}' .

#======================================================
wmessage "wrong order of arguments in call to memset)"

weggli -R 'func=memset(_explicit)?$' '{$func(_,_,0);}' .
weggli -R 'func=memset(_explicit)?$' '{$func(_,sizeof(_),_);}' .

#======================================================
wmessage "call to rand(), srand() (CWE-330, CWE-33)"

weggli -R 'func=s?rand$' '{$func();}' .

#======================================================
wmessage "source and destination overlap in sprintf(), snprintf)"
weggli -R 'func=^sn?printf$' '{$func($dst,_,$dst);}' .
weggli -R 'func=^sn?printf$' '{$func($dst,_,_,$dst);}' .
weggli -R 'func=^sn?printf$' '{$func($dst,_,_,_,$dst);}' .

#======================================================
wmessage "size check implemented with an assertion macro"
weggli -R 'assert=(?i)^\w*assert\w*\s*$' '{$assert(_<_);}' .
weggli -R 'assert=(?i)^\w*assert\w*\s*$' '{$assert(_<=_);}' .
weggli -R 'assert=(?i)^\w*assert\w*\s*$' '{$assert(_>_);}' .
weggli -R 'assert=(?i)^\w*assert\w*\s*$' '{$assert(_>=_);}' .

#======================================================
wmessage "unchecked return code of scanf(), etc. (CWE-25)"
weggli -R 'func=scanf$' '{strict:$func();}' .

#======================================================
wmessage "call to atoi(), atol(), atof(), atoll)"
weggli -R 'func=ato(i|ll?|f)$' '{$func();}' .

#======================================================
wmessage "command-line argument or environment variable access"
weggli -R 'var=argv|envp' '{$var[_];}' .

#======================================================
wmessage "missing default case in a switch construct (CWE-47)"
weggli -l 'switch(_) {_; not:default:_; _;}' .

#======================================================
wmessage "missing break or equivalent statement in a switch construct (CWE-48)"
weggli -l 'switch(_) {case _: not:break; not:exit; not:return; not:goto _; case _:_;}' .

#======================================================
wmessage "missing return statement in a non-void function (CWE-393, CWE-39)"
weggli -R 'type!=void' '$type $func(_) {_; not:return;}' .

#======================================================
wmessage "typos with security implications (CWE-480, CWE-481, CWE-482, CWE-48)"
weggli '{for (_==_;_;_) {}}' .
weggli 'if (_=_) {}' .
weggli 'if (_&_) {}' .
weggli 'if (_|_) {}' .
weggli '{_=+_;}' .
weggli '{_=-_;}' .
weggli -R 'func=strn?cpy$' 'if ($func()==_) {}' .

#======================================================
wmessage "keywords that suggest the presence of bugs"
weggli -R 'pattern=(?i)(unsafe|insecure|dangerous|warning|overflow)' '$pattern' .
weggli -R 'func=(?i)(encode|decode|convert|interpret|compress|fragment|reassemble)' '_ $func(_) {}' .
weggli -R 'func=(?i)(mutex|lock|toctou|parallelism|semaphore|retain|release|garbage|mutual)' '_ $func(_) {}' .


#========================================================

#========================================================

#========================================================

#========================================================

#========================================================

#========================================================

#========================================================

#========================================================



